import torch
import numpy as np
import onnxruntime as ort
import sys

sys.stdout.reconfigure(encoding='utf-8')

from stable_baselines3 import PPO
from godot_rl.wrappers.onnx.stable_baselines_export import OnnxablePolicy

model_path = r"DungeonMultiplayerGame-main\models\phase5_model.zip"
onnx_path = r"DungeonMultiplayerGame-main\models\phase5_model.onnx"

print(f"Loading model from {model_path}")
model = PPO.load(model_path)
policy = model.policy.to("cpu")

# Build the same OnnxablePolicy
onnxable_model = OnnxablePolicy(
    ["obs"],
    policy.features_extractor,
    policy.mlp_extractor,
    policy.action_net,
    policy.value_net,
    False,
)
onnxable_model.eval()

# Load ONNX model
ort_sess = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])

print("\n=== VERIFICATION: SB3 raw logits vs ONNX output ===")
mismatches = 0
for i in range(20):
    obs_sample = model.observation_space.sample()
    obs_np = obs_sample["obs"].astype(np.float32)
    
    # Get raw logits from SB3 (same as what OnnxablePolicy.forward returns)
    obs_dict = {"obs": torch.from_numpy(obs_np).unsqueeze(0).float()}
    with torch.no_grad():
        features = onnxable_model.features_extractor(obs_dict)
        action_hidden, _ = onnxable_model.mlp_extractor(features)
        action_logits_sb3 = onnxable_model.action_net(action_hidden)
    
    # Get ONNX output
    obs_for_onnx = np.expand_dims(obs_np, axis=0)
    action_onnx, _ = ort_sess.run(None, {
        "obs": obs_for_onnx,
        "state_ins": np.array([0.0], dtype=np.float32)
    })
    
    sb3_vals = action_logits_sb3.numpy().flatten()
    onnx_vals = np.array(action_onnx).flatten()
    
    match = np.allclose(sb3_vals, onnx_vals, atol=1e-4)
    if not match:
        mismatches += 1
        print(f"  Test {i}: MISMATCH!")
        print(f"    SB3:  {sb3_vals}")
        print(f"    ONNX: {onnx_vals}")
    else:
        # Show what actions would be chosen
        # move: logits[0:3], jump: logits[3:5], shoot: logits[5:7]
        move_action = np.argmax(onnx_vals[0:3])
        jump_action = np.argmax(onnx_vals[3:5])
        shoot_action = np.argmax(onnx_vals[5:7])
        move_names = ["left", "right", "idle"]
        jump_names = ["yes", "no"]
        shoot_names = ["no", "yes"]
        print(f"  Test {i}: OK  move={move_names[move_action]}, jump={jump_names[jump_action]}, shoot={shoot_names[shoot_action]}")

if mismatches == 0:
    print(f"\nAll 20 tests PASSED! ONNX export is CORRECT.")
else:
    print(f"\n{mismatches}/20 tests FAILED! Export is BROKEN.")
