import onnx
import os

onnx_path = r"DungeonMultiplayerGame-main\models\phase5_model.onnx"

print(f"Loading split model from {onnx_path}")
model = onnx.load(onnx_path)

print("Merging external data into single file...")
# When saving with onnx.save, if we don't specify external data, it tries to embed it by default unless it's too large.
# We explicitly ensure it's self-contained.
onnx.save_model(model, onnx_path, save_as_external_data=False)

print(f"Checking new file size...")
size = os.path.getsize(onnx_path)
print(f"New size: {size} bytes")

data_path = onnx_path + ".data"
if os.path.exists(data_path):
    print(f"Removing old .data file...")
    os.remove(data_path)

print("Self-contained model created.")
