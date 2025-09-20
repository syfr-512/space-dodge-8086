# 🚀 Space Dodge

> A retro 8086 assembly game where survival is the only rule.  
> Dodge falling meteors, control your spaceship, and prove your reflexes in the void of space.

---

## 🎮 Gameplay

You are the pilot of a tiny ASCII spaceship `<^>` floating in deep space.  
But danger lurks above — meteors `@` rain down endlessly. Your mission? **Dodge. Survive. Repeat.**

- Move left ⬅️ and right ➡️ with **A** and **D** keys.  
- Avoid meteors — a single hit means **Game Over**.  
- No second chances. Just pure reflex.  

**Will you master the chaos of the void?**

---

## 🕹️ Controls

| Key   | Action        |
|-------|---------------|
| `A`   | Move left     |
| `D`   | Move right    |
| `ESC` | Quit the game |

---

## 📦 Installation & Running

### Option 1 — Run in DOSBox (Recommended)
1. Download or clone this repo:
   ```bash
   git clone https://github.com/syfr-512/space-dodge-8086.git
2. Open DOSBox.

3. Mount the folder:
   mount c path\to\space-dodge-8086

4. Navigate to the drive:
   c:

5. Run the game:
SDODGE

### Option 2 — Compile Yourself (Two Ways)

I have already included a pre-compiled COM file specifically for DOSBOX but if you wish to compile it yourself, there's two ways of doing this.

(a) Using Emu8086 (Windows only. This is the one I used.)

1. Open SDODGE.asm in emu8086.

2. Assemble → Compile → Save as .COM.

3. Run in DOSBox as above.

(b) Using MASM/TASM + DOSBox (cross-platform, no Emu8086 needed)

1. Install MASM or TASM (available online, or bundled with DOSBox packs).

2. In DOSBox, mount & then navigate to the game folder:
i. mount c path\to\space-dodge-8086
ii. c:

3. Assemble the source:
masm SDODGE.ASM;
(or with TASM: tasm SDODGE.ASM)

4. Link to .COM:
link /T SDODGE.OBJ

5. Run it:
SDODGE

> ⚠️ NOTE: For DOSBox, file names must be 8 characters or fewer (not counting `.COM`).  
> `SDODGE.COM` is DOS-compatible, while `SPACE_DODGE.COM` will not run.
> There may be some code incompatibility when compiling with TASM/MASM so keep that in mind.


## 🎥 Demo



## ✨ Credits

Game created by: syfr

Built with raw 8086 Assembly in emu8086.

Runs flawlessly in DOSBox.

## ⚡️ Fun Fact

This entire game is written in low-level assembly language.
No fancy engines. No frameworks. Just pure 8086 metal.


