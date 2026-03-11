# Dungeon Multiplayer Game - RL Agent Enhancement

> **Original Credit:** [Sasath Ramawikrama (KingSalagoya)](https://github.com/KingSalagoya/DungeonMultiplayerGame)

This project builds upon a 2D Dungeon Multiplayer Game in Godot 4 by introducing a customized Reinforcement Learning (RL) opponent using **Stable Baselines 3** and **Godot RL Agents**. The final result is an intelligent bot capable of picking up weapons, tracking opponents, and engaging in combat using an embedded ONNX model.

## Key Features

* **Reinforcement Learning AI Controller**: Custom observation and action spaces implemented via `AIController2D`. The agent assesses map dimensions, weapon pickups, health pools, and enemy relative vectors to make decisions.
* **Stable Baselines 3 Training**: Included `stable_baselines3_example.py` script to train a `PPO` model directly interacting with the Godot environment.
* **Custom ONNX Export Pipeline**: Python tools to export the trained PyTorch models to game-ready `ONNX` networks. It bridges the data structure gap between SB3 output tensors and Godot's ONNX Inference node.

## Project Structure

* **`DungeonMultiplayerGame-main/`**: The core Godot project directory.
  * **`Scripts/ai_controller.gd`**: The brain attached to our agent, structuring environmental observations and unpacking discrete actions (move, jump, shoot) for the character.
  * **`models/phase5_model.onnx`**: The deployed, production-ready neural network model.
* **`stable_baselines3_example.py`**: A launcher for training the PPO RL agent. Can run synchronously with the Godot editor or with a compiled binary.
* **`export_model.py`**: Manual TorchScript-to-ONNX exportation script designed to correctly route dictionary-based observations.
* **`fix_onnx.py`** & **`verify_onnx.py`**: Utilities to rename model inputs (e.g. mapping `state_outs_orig` to `state_ins`) preventing graph execution errors in Godot, and verify ONNX behavior against SB3.

## Setup & Running the Game

1. Install **Godot 4.x**.
2. Open the Godot project located at `DungeonMultiplayerGame-main/`.
3. If necessary, confirm the `phase5_model.onnx` is successfully linked to your AI Controller node in the editor.
4. Run the project map instance to battle against the RL-driven enemy.

## Training the Agent

Setup a Python virtual environment and install the required dependencies (torch, stable-baselines3, onnx, onnxruntime, godot-rl). Then:

```bash
# Run training with the editor open, or pass --env_path to train on an exported binary
python stable_baselines3_example.py --experiment_name ai_training_run --timesteps 1000000
```

## Exporting Your Own Model to ONNX

After training, you can export the best SB3 zip model to an ONNX file recognized by Godot:

```bash
# Edit export_model.py to point at your new .zip model
python export_model.py

# Fix Godot specific input mappings if necessary
python fix_onnx.py

# Verify the ONNX model behaves exactly like the Python SB3 model
python verify_onnx.py
```
