#!/bin/bash

echo "🔧 Iniciando compilação..."

cd engine || exit 1

if [ ! -d build ]; then
    mkdir -p build
fi

cd build || exit 1

cmake .. || { echo "❌ Erro ao rodar cmake."; exit 1; }

# Tenta compilar, se falhar, remove build e recompila
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação. Tentando novamente com nova build..."
    cd ..
    rm -rf build
    mkdir -p build
    cd build || exit 1
    cmake .. || { echo "❌ Falha ao rodar cmake na nova build."; exit 1; }
    make -j$(nproc) || { echo "❌ Compilação falhou novamente. Abortando."; exit 1; }
fi

echo "✅ Compilação concluída. Movendo binário para a raiz..."
mv tfs ../..
cd ../..

echo "🚀 Iniciando servidor..."
./tfs
