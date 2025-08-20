#!/bin/bash

# Basilisk Master-Slave Coupling Compilation Script
# This script compiles the master-slave coupling example with proper environment setup
# Usage: ./compile.sh <slave_file> <master_file>

# Parse command line arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <slave_file> <master_file>"
    echo "Example: $0 subgrid.c outerDNS.c"
    exit 1
fi

SLAVE_FILE="$1"
MASTER_FILE="$2"

echo "🔧 Basilisk Master-Slave Coupling Compiler"
echo "==========================================="
echo "🔧 Slave file: $SLAVE_FILE"
echo "🔧 Master file: $MASTER_FILE"
echo ""

echo "📍 Working directory: $(pwd)"
echo "🛠️  BASILISK path: $BASILISK"
echo "🔍 qcc location: $(which qcc)"
echo "🎬 ppm2mp4 location: $(which ppm2mp4 2>/dev/null || echo \"not found\")"
echo "🎞️  ffmpeg location: $(which ffmpeg)"
echo ""

# Check if source files exist
if [ ! -f "$MASTER_FILE" ]; then
    echo "❌ Error: $MASTER_FILE not found!"
    exit 1
fi

if [ ! -f "$SLAVE_FILE" ]; then
    echo "❌ Error: $SLAVE_FILE not found!"
    exit 1
fi

echo "✅ Source files found"
echo ""

# Ensure Basilisk tools are built and available
if [ ! -f "$BASILISK/qcc" ]; then
    echo "🔨 qcc not found, building Basilisk first..."
    cd "$BASILISK"
    
    # Set up config if needed
    if [ ! -f "config" ] && [ -f "config.gcc" ]; then
        echo "🔗 Setting up config.gcc -> config"
        ln -sf config.gcc config
    fi
    
    # Build dependencies first
    echo "📦 Building AST library..."
    make -C ast libast.a || {
        echo "❌ Failed to build AST library"
        exit 1
    }
    
    echo "📦 Building include and postproc..."
    make include.o postproc.o || {
        echo "❌ Failed to build include.o postproc.o"
        exit 1
    }
    
    # Now build qcc
    echo "📦 Building qcc compiler..."
    make qcc || {
        echo "❌ Failed to build qcc"
        exit 1
    }
    
    # Make video tools executable
    chmod +x ppm2mp4 ppm2mpeg ppm2ogv ppm2gif 2>/dev/null || true
    
    # Return to work directory
    cd - > /dev/null
    
    echo "✅ Basilisk tools built successfully"
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
EXECUTABLE_NAME="${MASTER_FILE%.c}"
rm -f slave.o "$EXECUTABLE_NAME"

# Step 1: Compile slave to object file
echo "📝 Step 1: Compiling $SLAVE_FILE to object file..."
qcc -O2 -disable-dimensions -fno-common -D_OBJECT -c "$SLAVE_FILE" -o slave.o

if [ $? -ne 0 ]; then
    echo "❌ Failed to compile $SLAVE_FILE"
    exit 1
fi

echo "✅ slave.o created"

# Step 2: Filter symbols with objcopy (this is the key step that works on Linux)
echo "🔧 Step 2: Filtering symbols with GNU objcopy..."
objcopy -G slave_step -G slave_stop -G slave_interpolate slave.o

if [ $? -ne 0 ]; then
    echo "❌ Failed to filter symbols with objcopy"
    exit 1
fi

echo "✅ Symbols filtered (kept: slave_step, slave_stop, slave_interpolate)"

# Step 3: Compile master and link with filtered slave object
echo "🔗 Step 3: Linking $MASTER_FILE with filtered slave.o..."
qcc -disable-dimensions -O2 "$MASTER_FILE" slave.o -o "$EXECUTABLE_NAME" -lm

if [ $? -ne 0 ]; then
    echo "❌ Failed to link $EXECUTABLE_NAME"
    exit 1
fi

echo "✅ $EXECUTABLE_NAME executable created"
echo ""

# Verify the executable
if [ -f "$EXECUTABLE_NAME" ]; then
    echo "🎉 SUCCESS! Compilation completed successfully."
    echo ""
    echo "📊 File information:"
    ls -la "$EXECUTABLE_NAME" slave.o
    echo ""
    echo "🚀 To run the simulation:"
    echo "   ./$EXECUTABLE_NAME"
    echo ""
    echo "⏱️  To run for limited time:"
    echo "   timeout 30s ./$EXECUTABLE_NAME"
else
    echo "❌ ERROR: $EXECUTABLE_NAME executable not created"
    exit 1
fi
