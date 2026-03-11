import onnx
import sys

sys.stdout.reconfigure(encoding='utf-8')

onnx_path = r"DungeonMultiplayerGame-main\models\phase5_model.onnx"

print(f"Loading model from {onnx_path}")
model = onnx.load(onnx_path)

print("Current inputs:")
for inp in model.graph.input:
    print(f"  {inp.name}")

print("Current outputs:")
for out in model.graph.output:
    print(f"  {out.name}")

# Fix the input name: rename "state_outs_orig" to "state_ins"
for inp in model.graph.input:
    if inp.name == "state_outs_orig":
        print(f"Renaming input '{inp.name}' -> 'state_ins'")
        # Also need to rename any references in the graph nodes
        for node in model.graph.node:
            for i, input_name in enumerate(node.input):
                if input_name == "state_outs_orig":
                    node.input[i] = "state_ins"
        inp.name = "state_ins"

print("\nFixed inputs:")
for inp in model.graph.input:
    print(f"  {inp.name}")

print("\nFixed outputs:")
for out in model.graph.output:
    print(f"  {out.name}")

# Save the fixed model as a single self-contained file
onnx.save_model(model, onnx_path, save_as_external_data=False)

import os
print(f"\nSaved fixed model: {os.path.getsize(onnx_path)} bytes")
print("Done!")
