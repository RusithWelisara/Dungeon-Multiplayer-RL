import torch
import numpy as np
import onnx
import onnxruntime as ort
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')

from stable_baselines3 import PPO
from godot_rl.wrappers.onnx.stable_baselines_export import OnnxablePolicy

model_path = r"DungeonMultiplayerGame-main\models\phase5_model.zip"
onnx_path = r"DungeonMultiplayerGame-main\models\phase5_model.onnx"

print(f"Loading model from {model_path}")
model = PPO.load(model_path)
policy = model.policy.to("cpu")

# Build the OnnxablePolicy manually
onnxable_model = OnnxablePolicy(
    ["obs"],
    policy.features_extractor,
    policy.mlp_extractor,
    policy.action_net,
    policy.value_net,
    False,  # use_obs_array = False (dict obs)
)
onnxable_model.eval()  # IMPORTANT: set to eval mode

# Create dummy input matching the observation space
sample_obs = model.observation_space.sample()
dummy_input = [torch.from_numpy(sample_obs["obs"]).unsqueeze(0).float()]
dummy_state = torch.zeros(1).float()

# Delete old files
for f in [onnx_path, onnx_path + ".data"]:
    if os.path.exists(f):
        os.remove(f)

print(f"Exporting model to {onnx_path} using LEGACY exporter...")

# Force legacy TorchScript exporter by setting dynamo=False
torch.onnx.export(
    onnxable_model,
    args=(dummy_input, dummy_state),
    f=onnx_path,
    opset_version=17,
    dynamo=False,  # FORCE LEGACY EXPORTER
    input_names=["obs", "state_ins"],
    output_names=["output", "state_outs"],
    dynamic_axes={
        "obs": {0: "batch_size"},
        "state_ins": {0: "batch_size"},
        "output": {0: "batch_size"},
        "state_outs": {0: "batch_size"},
    },
)

# Merge external data if split
if os.path.exists(onnx_path + ".data"):
    print("Merging split model into single file...")
    m = onnx.load(onnx_path)
    onnx.save_model(m, onnx_path, save_as_external_data=False)
    os.remove(onnx_path + ".data")

print(f"Model size: {os.path.getsize(onnx_path)} bytes")

# Fix input names if needed
m = onnx.load(onnx_path)
needs_fix = False
for inp in m.graph.input:
    if inp.name != "obs" and inp.name != "state_ins":
        print(f"Fixing input name: '{inp.name}' -> 'state_ins'")
        for node in m.graph.node:
            for i, input_name in enumerate(node.input):
                if input_name == inp.name:
                    node.input[i] = "state_ins"
        inp.name = "state_ins"
        needs_fix = True

if needs_fix:
    onnx.save_model(m, onnx_path, save_as_external_data=False)
    print("Input names fixed.")

# VERIFY: Compare SB3 output vs ONNX output
print("\n=== VERIFICATION ===")
ort_sess = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])

mismatches = 0
for i in range(20):
    obs_sample = model.observation_space.sample()
    obs_np = obs_sample["obs"].astype(np.float32)
    
    # SB3 prediction
    obs_tensor = {"obs": torch.from_numpy(obs_np).unsqueeze(0).float()}
    with torch.no_grad():
        action_sb3, _, _ = policy(obs_tensor, deterministic=True)
    
    # ONNX prediction
    obs_for_onnx = np.expand_dims(obs_np, axis=0)
    action_onnx, _ = ort_sess.run(None, {
        "obs": obs_for_onnx,
        "state_ins": np.array([0.0], dtype=np.float32)
    })
    
    sb3_vals = action_sb3.numpy().flatten()
    onnx_vals = np.array(action_onnx).flatten()
    
    match = np.allclose(sb3_vals, onnx_vals, atol=1e-4)
    if not match:
        mismatches += 1
        print(f"  Test {i}: MISMATCH! SB3={sb3_vals} vs ONNX={onnx_vals}")
    else:
        print(f"  Test {i}: OK  SB3={sb3_vals[:3]}... ONNX={onnx_vals[:3]}...")

if mismatches == 0:
    print("\nAll 20 tests PASSED! Model export is correct.")
else:
    print(f"\n{mismatches}/20 tests FAILED! Export is broken.")
