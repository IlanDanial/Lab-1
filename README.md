# Lab 1: Correct GPU Vector Addition

**Class:** EEL 4930 – Introduction to GPU Computing (Fall 2026)  
**Name:** Ilan Danial  

---

## 1. Environment & Hardware Specifications

- **Compute Node:** `c1105a-s10.ufhpc`
- **GPU Model:** NVIDIA L4 (23,034 MiB)
- **NVIDIA Driver:** 580.178.04
- **CUDA Toolkit:** Release 13.2, V13.2.78
- **Host Compiler:** GCC 14.2.0

---

## 2. Build & Run Instructions

### Build:
```bash
module load gcc cuda
make clean
make
```

### Run:
- **Interactive single run:**
  ```bash
  ./lab1 1000
  ```
- **Automated batch submission:**
  ```bash
  sbatch run.slurm
  ```

---

## 3. Correctness & Performance Test Matrix

The block size was fixed at **256 threads per block**. Each test case was verified against the CPU reference within a floating-point tolerance of `1e-5`.

| Test Case ($N$) | Launch Configuration (Blocks $\times$ Threads) | Verification | CPU 1-Thread Time | CPU 96-Thread Time | GPU Kernel Time | Application Time |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **$N = 1$** | $1 \times 256$ | **PASS** | 0.000250 ms | 1.307720 ms | 0.007000 ms | 0.020982 ms |
| **$N = 255$** | $1 \times 256$ | **PASS** | 0.000140 ms | 1.401804 ms | 0.006880 ms | 0.021263 ms |
| **$N = 256$** | $1 \times 256$ | **PASS** | 0.000140 ms | 1.387432 ms | 0.006860 ms | 0.022013 ms |
| **$N = 257$** | $2 \times 256$ | **PASS** | 0.000140 ms | 1.269372 ms | 0.007030 ms | 0.022694 ms |
| **$N = 1\,000$** | $4 \times 256$ | **PASS** | 0.000191 ms | 1.311836 ms | 0.007121 ms | 0.022314 ms |
| **$N = 10\,000\,000$** | $39\,063 \times 256$ | **PASS** | 3.030101 ms | 3.414206 ms | 0.491247 ms | 6.100273 ms |

---

## 4. Ceiling Division & Thread Guard

The problem with standard integer division fails for chunking since the division operator in c++ will round down it will miss work that needs to be done. The kernel boundary gaurd, protects memory by preventing the thread from accessing memory that does not exist for example if there are more threads than there are N in the array it will prevent the program from accessing garbage memory.

---

## 5. Problem Encountered & Resolution

One issue I encountered during the lab was running my script through hipergator, to trouble shoot I used the terminal to diagnose the issue and went back and forth with online resources to fix and optimize it. The key issues layed in my make file and in my slurm file, my make clean command cleaning out my outputs and makefile having the wrong env parameters.

---

## 6. Disclosure of AI Assistance

I used Google Antigravity, I used it for double checking assignment requirements, configuring the slurm submission headers, and debugging my compiler issues, and was also used to format (not write) the readme file.
I verified my code by running it on HiPerGator.

