#!/bin/bash
# OTG Custom Build System - Multi-OS Support
# Créditos: Mateus Roberto (mateuskl no GitHub)

# Cores para a interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir o banner
show_banner() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${GREEN}🚀 OTG Custom Build System - Multi-OS Support${NC}"
    echo -e "${YELLOW}Créditos: Mateus Roberto (mateuskl no GitHub)${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo
}

# Função para verificar e instalar bibliotecas
check_libraries() {
    local os_choice=$1
    echo -e "${YELLOW}🔍 Verificando bibliotecas necessárias para $os_choice...${NC}"
    local libs=(
        git cmake g++ libcrypto++-dev libcrypto++-doc libcrypto++-utils
        libpugixml-dev libfmt-dev
    )
    case $os_choice in
        "Debian 10"|"Debian 11")
            libs+=(libluajit-5.1-dev libmariadb-dev-compat libboost-date-time-dev
                   libboost-system-dev libboost-iostreams-dev libboost-filesystem-dev)
            ;;
        "Ubuntu 20.04")
            libs+=(libluajit-5.1-dev libmysqlclient-dev libboost-date-time-dev
                   libboost-system-dev libboost-iostreams-dev libboost-filesystem-dev
                   liblua5.2-dev libboost-all-dev)
            ;;
        "Ubuntu 22.04")
            libs+=(libmysqlclient-dev liblua5.2-dev libboost-all-dev)
            ;;
        *)
            echo -e "${RED}❌ Sistema operacional inválido!${NC}"
            return 1
            ;;
    esac

    local missing_libs=()
    for lib in "${libs[@]}"; do
        if ! dpkg -l | grep -q "$lib" || ! apt-cache policy "$lib" | grep -q "Installed:.*[0-9]"; then
            missing_libs+=("$lib")
        fi
    done

    if [ ${#missing_libs[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Todas as bibliotecas estão instaladas!${NC}"
        if dpkg -l | grep -q "libboost.*1.81"; then
            echo -e "${YELLOW}⚠️ Detectada versão Boost 1.81. Deseja substituí-la por Boost 1.74?${NC}"
            read -p "(s/n): " choice
            if [[ "$choice" == "s" || "$choice" == "S" ]]; then
                echo -e "${YELLOW}🧹 Removendo Boost 1.81...${NC}"
                sudo dpkg -l | grep "libboost.*1.81" | awk '{print $2}' | xargs -r sudo apt remove --purge -y
                sudo apt autoremove -y
                echo -e "${YELLOW}📦 Instalando libboost-all-dev (Boost 1.74)...${NC}"
                sudo apt install libboost-all-dev -y
            fi
        fi
    else
        echo -e "${RED}⚠️ Bibliotecas faltando: ${missing_libs[*]}${NC}"
        echo -e "${YELLOW}📦 Instalando bibliotecas...${NC}"
        sudo apt update
        sudo apt install "${missing_libs[@]}" -y
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Bibliotecas instaladas com sucesso!${NC}"
        else
            echo -e "${RED}❌ Erro ao instalar bibliotecas. Verifique sua conexão ou permissões.${NC}"
            return 1
        fi
    fi
}

# Função para compilar o projeto
compile_project() {
    echo -e "${YELLOW}🔧 Iniciando build check para OTG Custom...${NC}"

    # Verificar se o diretório engine existe
    if [ ! -d "engine" ]; then
        echo -e "${RED}❌ Diretório 'engine' não encontrado!${NC}"
        echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
        read
        return
    fi

    cd engine

    # Verificar alterações no código-fonte com git
    echo -e "${YELLOW}🔍 Verificando alterações no código-fonte (.cpp, .h)...${NC}"
    current_changes=""
    commit_hash=""

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        current_changes=$(git status --porcelain | grep -E '\.cpp$|\.h$' | awk '{print $2}' | sort | uniq)
        commit_hash=$(git rev-parse HEAD)

        if [ -z "$current_changes" ]; then
            echo -e "${GREEN}✅ Nenhuma alteração nos arquivos .cpp ou .h.${NC}"
        else
            echo -e "${YELLOW}⚠️ Alterações detectadas nos arquivos .cpp ou .h:${NC}"
            echo "$current_changes"
        fi
    else
        echo -e "${YELLOW}⚠️ Diretório não é um repositório git. Ignorando verificação de alterações.${NC}"
    fi

    # Verificar/criar diretório build
    [ -d build ] || mkdir -p build

    # Verificar histórico de compilação
    HISTORY_LOG="build/compile_history.log"
    BUILD_LOG="build/build.log"

    skip_compile=0

    if [ -f "$HISTORY_LOG" ] && [ -f "$BUILD_LOG" ] && [ -f "build/tfs" ] || [ -f "../tfs" ]; then
        if ! grep -q "error\|fatal\|failed" "$BUILD_LOG"; then
            last_files=$(grep '^engine/' "$HISTORY_LOG" 2>/dev/null | sort | uniq)
            last_commit=$(grep '^Commit:' "$HISTORY_LOG" 2>/dev/null | tail -1 | awk '{print $2}')

            if [ -n "$current_changes" ] && [ "$current_changes" = "$last_files" ] && [ "$commit_hash" = "$last_commit" ]; then
                echo -e "${GREEN}✅ Alterações já compiladas anteriormente (mesmos arquivos e commit).${NC}"
                skip_compile=1

                if [ -f "build/tfs" ]; then
                    echo -e "${GREEN}✅ Binário tfs encontrado na pasta build.${NC}"
                    cp build/tfs ..
                fi

                if [ -f "../tfs" ]; then
                    echo -e "${GREEN}✅ Binário 'tfs' já está no diretório principal!${NC}"
                    cd ..
                    show_run_menu
                    return
                fi
            fi
        else
            echo -e "${YELLOW}⚠️ Build anterior contém erros. Recompilando...${NC}"
        fi
    fi

    if [ $skip_compile -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')]" > "$HISTORY_LOG"
        if [ -n "$commit_hash" ]; then
            echo "Commit: $commit_hash" >> "$HISTORY_LOG"
        else
            echo "Commit: N/A (não é um repositório git)" >> "$HISTORY_LOG"
        fi
        echo "Files:" >> "$HISTORY_LOG"
        if [ -n "$current_changes" ]; then
            echo "$current_changes" >> "$HISTORY_LOG"
        else
            echo "Nenhum arquivo .cpp ou .h alterado" >> "$HISTORY_LOG"
        fi
        echo "Status: Compiling" >> "$HISTORY_LOG"

        cd build

        echo -e "${BLUE}📄 Iniciando cmake...${NC}"
        set +e
        cmake .. 2>&1 | tee build.log
        cmake_status=$?

        if [ $cmake_status -ne 0 ]; then
            echo -e "${RED}❌ Erro durante o cmake. Verifique o log em engine/build/build.log.${NC}"
            echo "Status: Failed - cmake" >> ../"$HISTORY_LOG"
            echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
            read
            cd ../..
            return
        fi

        echo -e "${BLUE}🔨 Compilando com make -j$(nproc)...${NC}"
        make -j$(nproc) 2>&1 | tee -a build.log
        make_status=$?

        if [ $make_status -ne 0 ]; then
            echo -e "${RED}❌ Erro durante a compilação. Verifique o log em engine/build/build.log.${NC}"
            echo "Status: Failed - make" >> ../"$HISTORY_LOG"
            echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
            read
            cd ../..
            return
        fi
        set -e
    else
        cd build
    fi

    if [ -f tfs ]; then
        echo -e "${GREEN}✅ Compilação concluída com sucesso!${NC}"
        cp tfs ../..
        echo "Status: Success" >> ../"$HISTORY_LOG"
        cd ../..
        show_run_menu
    else
        echo -e "${RED}❌ Binário 'tfs' não encontrado após compilação.${NC}"
        echo "Status: Failed - no tfs binary" >> ../"$HISTORY_LOG"

        if [ -f "../tfs" ]; then
            echo -e "${YELLOW}⚠️ Usando binário anterior no diretório principal.${NC}"
            cd ../..
            show_run_menu
        else
            echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
            read
            cd ../..
        fi
    fi
}

# Função para exibir o submenu de execução do tfs
show_run_menu() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${GREEN}✅ Binário 'tfs' está pronto no diretório principal!${NC}"
    echo -e "${BLUE}Escolha uma opção:${NC}"
    echo -e "${GREEN}1️⃣  Executar ./tfs agora${NC}"
    echo -e "${GREEN}2️⃣  Voltar ao menu principal${NC}"
    echo -e "${RED}3️⃣  Sair${NC}"
    read -p "Digite sua escolha (1-3): " run_choice

    case $run_choice in
        1)
            run_server
            ;;
        2)
            echo -e "${YELLOW}⚠️ Voltando ao menu principal...${NC}"
            ;;
        3)
            echo -e "${BLUE}🚀 Até mais, foi ótimo te ajudar! Nos vemos em breve!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida! Voltando ao menu principal...${NC}"
            ;;
    esac
}

# Função para executar o servidor
run_server() {
    if [ -f tfs ]; then
        echo -e "${GREEN}🚀 Iniciando servidor...${NC}"
        ./tfs
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
    else
        echo -e "${RED}❌ Binário 'tfs' não encontrado. Compile primeiro!${NC}"
        echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
        read
    fi
}

# Submenu para escolher o sistema operacional
show_os_menu() {
    show_banner
    echo -e "${BLUE}Selecione o sistema operacional:${NC}"
    echo -e "${GREEN}1️⃣  Debian 10${NC}"
    echo -e "${GREEN}2️⃣  Debian 11${NC}"
    echo -e "${GREEN}3️⃣  Ubuntu 20.04${NC}"
    echo -e "${GREEN}4️⃣  Ubuntu 22.04${NC}"
    echo -e "${GREEN}5️⃣  Voltar ao menu principal${NC}"
    echo -e "${RED}6️⃣  Sair${NC}"
    read -p "Digite sua escolha (1-6): " os_choice

    case $os_choice in
        1)
            check_libraries "Debian 10"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
        2)
            check_libraries "Debian 11"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
        3)
            check_libraries "Ubuntu 20.04"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
        4)
            check_libraries "Ubuntu 22.04"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
        5)
            return 0
            ;;
        6)
            echo -e "${BLUE}🚀 Até mais, foi ótimo te ajudar! Nos vemos em breve!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida! Escolha entre 1 e 6.${NC}"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
    esac
}

# Menu principal
show_main_menu() {
    show_banner
    echo -e "${BLUE}Selecione uma opção:${NC}"
    echo -e "${GREEN}1️⃣  Verificar/Instalar bibliotecas${NC}"
    echo -e "${GREEN}2️⃣  Compilar projeto${NC}"
    echo -e "${GREEN}3️⃣  Executar servidor${NC}"
    echo -e "${RED}4️⃣  Sair${NC}"
    read -p "Digite sua escolha (1-4): " choice

    case $choice in
        1)
            show_os_menu
            ;;
        2)
            compile_project
            ;;
        3)
            run_server
            ;;
        4)
            echo -e "${BLUE}🚀 Até mais, foi ótimo te ajudar! Nos vemos em breve!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida! Escolha entre 1 e 4.${NC}"
            echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
            read
            ;;
    esac
}

# Loop principal
set -e
while true; do
    show_main_menu
done