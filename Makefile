NVCC := nvcc
CXX  := g++

# HiPerGator GPU flags
NVCC_FLAGS := -O3 -std=c++17 -Xcompiler -Wall,-Wextra
INCLUDES   := -I../include -I.

# Target executable name (default to lab1)
TARGET := lab1

# Collect all .cu and .cpp files in this directory
CU_SRCS  := $(wildcard *.cu)
CPP_SRCS := $(wildcard *.cpp)
OBJS     := $(CU_SRCS:.cu=.o) $(CPP_SRCS:.cpp=.o)

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(OBJS)
	$(NVCC) $(NVCC_FLAGS) $(OBJS) -o $(TARGET)

%.o: %.cu
	$(NVCC) $(NVCC_FLAGS) $(INCLUDES) -c $< -o $@

%.o: %.cpp
	$(CXX) -O3 -std=c++17 -Wall -Wextra $(INCLUDES) -c $< -o $@

clean:
	rm -f $(TARGET) *.o slurm-*.out slurm-*.err

run: $(TARGET)
	./$(TARGET)
