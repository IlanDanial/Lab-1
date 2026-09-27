#include <cuda_runtime.h>
#include <cmath> 
#include <cstdio>
#include <cstdlib> 
#include <vector>
#include <thread>
#include <chrono>
#include <iostream>
#include <iomanip>
using namespace std;

inline void cuda_check(cudaError_t e) {
    if (e != cudaSuccess) {
        std::fprintf(stderr, "CUDA: %s\n", cudaGetErrorString(e));
        std::exit(1);
    }
}
#define CUDA_CHECK(call) cuda_check(call)

void add_range(const float* x, const float* y, float* z, int begin, int end) { for (int i = begin; i < end; ++i) z[i] = x[i] + y[i]; }
__global__ void vecadd_kernel(const float* x, const float* y, float* z, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {z[i] = x[i] + y[i];}
}
void vecadd_cpu_mt(const float* x, const float* y, float* z, int N, int T) {
    int chunk = (N + T - 1) / T;
    std::vector<std::thread> workers;
    for (int t = 0; t < T; ++t) {
        int begin = t * chunk, end = std::min(begin + chunk, N);
        workers.emplace_back(add_range, x, y, z, begin, end);
    }
    for (auto& worker : workers) worker.join();
}

void vecadd_cpu(const float* x, const float* y, float* z, int N) {
    for (int i = 0; i < N; ++i) z[i] = x[i] + y[i];
}

bool verify(const float* got, const float* ref, int N, float tol) {
    for (int i = 0; i < N; ++i) {
        if (std::fabs(got[i] - ref[i]) > tol) return false;
    }
    return true;
}


int main(int argc, char** argv) {

    // Grab N from command line arg
    int N = (argc > 1) ? std::atoi(argv[1]) : 1000;
    //initialize variables
    size_t bytes = size_t(N) * sizeof(float);
    std::vector<float> x(N, 1.0f), y(N, 2.0f);
    std::vector<float> got(N), ref(N);
    int T = thread::hardware_concurrency();
    if (T == 0) T = 4;

    // single thread
    auto start_cpu = chrono::high_resolution_clock::now();
    vecadd_cpu(x.data(), y.data(), ref.data(), N);
    auto end_cpu = chrono::high_resolution_clock::now();
    chrono::duration<double, milli> cpu_st_ms = end_cpu - start_cpu;

    //multi thread
    auto start_cpu_mt = chrono::high_resolution_clock::now();
    vecadd_cpu_mt(x.data(), y.data(), ref.data(), N, T);
    auto end_cpu_mt = chrono::high_resolution_clock::now();
    chrono::duration<double, milli> cpu_mt_ms = end_cpu_mt - start_cpu_mt;

    //warm up
    // initialize memory pointers
    float *d_x, *d_y, *d_z;

    // allocate memory
    CUDA_CHECK(cudaMalloc(&d_x, bytes));
    CUDA_CHECK(cudaMalloc(&d_y, bytes));
    CUDA_CHECK(cudaMalloc(&d_z, bytes));
    // move data to gpu
    CUDA_CHECK(cudaMemcpy(d_x, x.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, y.data(), bytes, cudaMemcpyHostToDevice));
    const int threadsPerBlock = 256;
    const int numBlocks = (N + threadsPerBlock - 1) / threadsPerBlock;
    //run kernel
    vecadd_kernel<<<numBlocks, threadsPerBlock>>>(d_x, d_y, d_z, N);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    // get data back to cpu
    CUDA_CHECK(cudaMemcpy(got.data(), d_z, bytes, cudaMemcpyDeviceToHost));
    bool pass = verify(got.data(), ref.data(), N, 1e-5f);

    auto start_transfer = chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(d_x, x.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, y.data(), bytes, cudaMemcpyHostToDevice));

    auto start_gpu = chrono::high_resolution_clock::now();
    vecadd_kernel<<<numBlocks, threadsPerBlock>>>(d_x, d_y, d_z, N);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    auto end_gpu = chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(got.data(), d_z, bytes, cudaMemcpyDeviceToHost));
    auto end_transfer = chrono::high_resolution_clock::now();
    pass = verify(got.data(), ref.data(), N, 1e-5f);
    printf("%s N=%d\n", pass ? "PASS" : "FAIL", N);
    // de allocate from the gpu
    CUDA_CHECK(cudaFree(d_x)); CUDA_CHECK(cudaFree(d_y)); CUDA_CHECK(cudaFree(d_z));
    
    chrono::duration<double, milli> app_ms = end_transfer - start_transfer;
    chrono::duration<double, milli> gpu_ms = end_gpu - start_gpu;
    cout << fixed << setprecision(6);
    cout << " " << left << setw(26) << "CPU (Single-Thread) Time:" << right << setw(10) << cpu_st_ms.count() << " ms" << endl;
    cout << " " << left << setw(26) << ("CPU (" + to_string(T) + "-Thread) Time:") << right << setw(10) << cpu_mt_ms.count() << " ms" << endl;
    cout << " " << left << setw(26) << "GPU Time:" << right << setw(10) << gpu_ms.count() << " ms" << endl;
    cout << " " << left << setw(26) << "Application Time:" << right << setw(10) << app_ms.count() << " ms" << endl;
    return pass ? 0 : 1;
}
