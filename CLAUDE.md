# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a master-slave computational fluid dynamics simulation framework built on top of the Basilisk CFD framework. The project demonstrates how to couple two Basilisk solvers running simultaneously - a "slave" solver generating a von Karman vortex street and a "master" solver using the slave's output as boundary conditions.

## Project Structure

- **`basilisk/`** - Complete Basilisk CFD framework source code (darcs version control) --> this is READ-ONLY. Do not edit this directory or any files in it.
  - **`src/`** - Core Basilisk framework with solvers, grid systems, and utilities
  - **`src/master.h`** and **`src/slave.h`** - Coupling interface for master-slave simulations
- **`simulationCases/`** - Master-slave coupling example implementations
  - **`master.c`** - Master solver (straight channel flow with slave boundary conditions)
  - **`slave.c`** - Slave solver (von Karman vortex street generator) 
  - **`compile.sh`** - Specialized compilation script for master-slave coupling
- **`reset_install_requirements.sh`** - Environment setup and Basilisk installation script

## Core Architecture

### Master-Slave Coupling System
The framework implements a sophisticated one-way coupling where:

1. **Slave Solver** (`slave.c`) generates a von Karman vortex street using embedded boundaries
2. **Master Solver** (`master.c`) samples the slave's velocity field along a vertical line and uses these values as inflow boundary conditions
3. **Coupling Interface** (`master.h`/`slave.h`) provides synchronization and interpolation functions:
   - `slave_interpolate()` - Retrieves interpolated field values from slave
   - `slave_step()` - Synchronizes master/slave timesteps
   - `slave_stop()` - Cleanup function

### Basilisk Framework Integration
- Uses Basilisk's adaptive mesh refinement capabilities
- Supports embedded boundary methods for complex geometries
- Implements Navier-Stokes solvers with various grid types (multigrid, octree)
- Includes visualization tools (`bview2D`, `bview3D`) and movie generation

## Essential Commands

### Environment Setup
```bash
# Initial setup (installs Basilisk if needed)
./reset_install_requirements.sh

# Hard reset (forces Basilisk reinstallation)
./reset_install_requirements.sh --hard

# Source environment (after setup)
source .project_config
```

### Building and Running Simulations

#### Master-Slave Coupling
```bash
cd simulationCases

# Compile master-slave coupling (specialized process)
./compile.sh slave.c master.c

# Run the coupled simulation
./master

# Run with timeout (for testing)
timeout 30s ./master
```

#### Manual Compilation Process
The coupling requires a specific compilation sequence:
```bash
# Step 1: Compile slave to object file
qcc -O2 -disable-dimensions -fno-common -D_OBJECT -c slave.c -o slave.o

# Step 2: Filter symbols (Linux/GNU objcopy)
objcopy -G slave_step -G slave_stop -G slave_interpolate slave.o

# Step 3: Link master with filtered slave object
qcc -disable-dimensions -O2 master.c slave.o -o master -lm
```

### Basilisk Framework Commands
```bash
cd basilisk/src

# Build Basilisk framework
make -k  # Continue on errors
make     # Final build

# Build specific tools
make qcc          # Basilisk compiler
make bview2D      # 2D visualization tool
make bview3D      # 3D visualization tool

# Run tests
./runtest examples/  # Run all examples
```

### Development and Testing
```bash
# Check qcc installation
qcc --version

# Test compilation
qcc -version
qcc -autolink test.c -o test

# Generate movies (if ppm files exist)
ppm2mp4 *.ppm       # Convert PPM to MP4
ppm2gif *.ppm       # Convert PPM to GIF
```

## Key Implementation Details

### Compilation Requirements
- **GNU objcopy** required for symbol filtering on Linux systems
- **Xcode Command Line Tools** required on macOS
- Symbol filtering keeps only: `slave_step`, `slave_stop`, `slave_interpolate`

### Solver Configuration
- **Reynolds number**: 160 (typical for von Karman street)
- **Domain discretization**: Adaptive mesh refinement (max level 9)
- **Embedded boundaries**: Circular cylinder (diameter 0.5)
- **Boundary conditions**: Dirichlet inflow, Neumann outflow

### Synchronization Mechanism
- Master and slave run simultaneously in the same process
- Slave simulation starts at `t = slave_start` (configurable offset)
- Master queries slave fields via `slave_interpolate()` at each timestep
- Both solvers use compatible timestep management

## Environment Variables
After running the setup script, these are automatically configured:
```bash
export BASILISK=/path/to/basilisk/src
export PATH=$PATH:$BASILISK
```

## Common Troubleshooting

### Build Issues
- Ensure Xcode Command Line Tools installed: `xcode-select --install`
- Check qcc availability: `which qcc`
- Verify BASILISK environment variable is set
- Use `make -k` to continue build despite non-critical errors

### Runtime Issues
- Check that both master.c and slave.c exist before compilation
- Verify objcopy is available (GNU binutils)
- Ensure sufficient memory for adaptive mesh refinement
- Use timeout for testing to avoid infinite runs

### Symbol Filtering
The objcopy step is critical for proper linking. It ensures only the required coupling functions are exported from the slave object file, preventing symbol conflicts between master and slave solvers.