# 🚀 ESP-IDF Dev Template

Template de ambiente de desenvolvimento para projetos **ESP-IDF**, baseado em **Docker** e **VS Code Dev Containers**.

A proposta é permitir que um desenvolvedor clone o repositório, abra o projeto no VS Code e tenha um ambiente ESP-IDF completo e reproduzível sem precisar instalar toolchains, Python environments, CMake, Ninja, OpenOCD ou outras dependências de desenvolvimento diretamente no sistema operacional host.

---

## 📌 Por que este projeto existe?

Preparar manualmente um ambiente ESP-IDF pode envolver diversas ferramentas e dependências. Além da instalação inicial, essas ferramentas precisam continuar compatíveis entre si.

Isso pode gerar problemas como:

* diferenças de ambiente entre desenvolvedores;
* conflitos entre instalações;
* ferramentas presentes em uma máquina e ausentes em outra;
* dependências instaladas globalmente no sistema;
* dificuldades para reproduzir um ambiente antigo;
* necessidade de reconfigurar uma máquina nova;
* arquivos gerados com permissões incorretas;
* diferenças entre o ambiente local e CI.

Este projeto utiliza um **Dev Container** para manter o ambiente de desenvolvimento dentro de uma imagem Docker.

Dessa forma, o host fica responsável basicamente por:

* Docker;
* VS Code;
* extensão Dev Containers;
* acesso ao hardware USB/serial quando necessário.

Toolchains, bibliotecas, ferramentas de análise e demais dependências permanecem dentro do ambiente do projeto.

```text
┌─────────────── Host ────────────────┐
│                                     |
│  Docker                             |
│  VS Code                            |
│  Dev Containers                     |
│                                     |
│    ┌── ESP-IDF Dev Container ──┐    │
│   │                            │    │
│   │  ESP-IDF                   │    │
│   │  Toolchains                │    │
│   │  Python                    │    │
│   │  Build tools               │    │
│   │  Analysis tools            │    │
│   │  Serial / USB tools        │    │
│   │                            │    │
│   └────────────────────────────┘    │ 
│                                     │
└─────────────────────────────────────┘
```

---

## 🎯 Objetivos

O template foi criado para fornecer:

* ambiente de desenvolvimento isolado do host;
* instalação automática das ferramentas necessárias;
* ambiente reproduzível entre diferentes desenvolvedores;
* uso da imagem oficial `espressif/idf`;
* configuração inicial do VS Code;
* ferramentas de formatação e análise estática;
* cache persistente de compilação;
* usuário não-root dentro do container;
* ferramentas auxiliares para criação e diagnóstico do projeto;
* base para acesso a interfaces serial e USB;
* facilidade para adicionar novas dependências sem modificar o host.

O template não substitui o ESP-IDF nem cria uma camada própria sobre seu sistema de build.

Depois que o ambiente está configurado, os comandos do frontend IDF (`idf.py`) continuam sendo utilizados:

```bash
idf.py build
idf.py menuconfig
idf.py flash
idf.py monitor
```

---

## ⚡ Quick Start

### 1. Requisitos no host

Para utilizar o template, o host precisa possuir:

* Docker;
* VS Code;
* extensão **Dev Containers**.

Não é necessário instalar ESP-IDF, toolchains ou suas dependências diretamente no host.

### 2. Abrir o projeto

Clone ou crie um novo repositório utilizando este projeto como base.

Abra o diretório:

```bash
code .
```

No VS Code, execute:

```text
Dev Containers: Reopen in Container
```

O fluxo inicial será aproximadamente:

```text
Dockerfile
    ↓
build da imagem
    ↓
criação do container
    ↓
mount do projeto
    ↓
setup-dev-env.sh
    ↓
ambiente pronto
```

> ⚠️ **NOTA:** A primeira criação pode levar mais tempo devido ao download da imagem e instalação das dependências. Builds posteriores normalmente reutilizam o cache do Docker.

### 3. Inicializar o projeto

Dentro do container, utilize:

```bash
esp-init <project_name> <target> [version]
```

Exemplo:

```bash
esp-init my_firmware esp32s3
```

Também é possível informar a versão inicial do firmware:

```bash
esp-init my_firmware esp32s3 1.0.0
```

Caso a versão seja omitida, será utilizada:

```text
0.1.0
```

> ⚠️ **NOTA:** A versão é armazenada em `version.txt`, facilitando seu uso por scripts, CI/CD, geração de artefatos e pelo próprio sistema de build do projeto.

Para consultar os argumentos disponíveis:

```bash
esp-init --help
```

---

## 🔧 O que `esp-init` faz?

O `esp-init` automatiza a preparação inicial de um novo projeto.

```text
esp-init
   │
   ├── verifica o ambiente ESP-IDF
   ├── valida o nome do projeto
   ├── valida permissões
   ├── verifica se já existe um projeto
   ├── valida o target informado
   ├── cria o projeto utilizando idf.py
   ├── cria version.txt
   ├── configura sdkconfig.defaults
   ├── aplica clang-format quando disponível
   ├── configura o target
   └── executa o primeiro build
        │
        ▼
   projeto pronto
```

Sempre que possível, o script utiliza diretamente as ferramentas fornecidas pelo ESP-IDF em vez de reproduzir sua lógica internamente.

---

## 🧰 Comandos auxiliares

O template adiciona alguns comandos para tarefas relacionadas ao ambiente:

| Comando     | Função                                         |
| ----------- | ---------------------------------------------- |
| `esp-init`  | Inicializa um novo projeto ESP-IDF             |
| `esp-info`  | Exibe informações sobre o ambiente e o projeto |
| `esp-setup` | Reexecuta a configuração inicial do ambiente   |

### `esp-info`

O comando:

```bash
esp-info
```

apresenta informações úteis como:

```text
ESP-IDF
IDF_PATH
versão configurada no container
nome do projeto
target
versão do firmware
```

> ⚠️ **NOTA:** O `esp-info` não é executado automaticamente ao abrir um terminal para não adicionar tempo desnecessário à inicialização do shell.

---

## 📁 Arquivos do template

Os principais arquivos do ambiente são:

| Arquivo                           | Função                                                                                   |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `.devcontainer/Dockerfile`        | Define a imagem, pacotes Linux, usuário, permissões e configurações de build do ambiente |
| `.devcontainer/devcontainer.json` | Define como o VS Code cria e utiliza o container                                         |
| `.devcontainer/setup-dev-env.sh`  | Executa a configuração inicial após a criação do container                               |
| `.devcontainer/init-project.sh`   | Implementa o comando `esp-init`                                                          |
| `.devcontainer/project-info.sh`   | Implementa o comando `esp-info`                                                          |
| `.devcontainer/config/bashrc.sh`  | Carrega o ambiente ESP-IDF e registra os aliases do template                             |
| `.clang-format`                   | Define as regras de formatação de código C/C++                                           |
| `.editorconfig`                   | Define regras básicas de edição compartilhadas entre diferentes editores                 |
| `.gitignore`                      | Define os arquivos e diretórios que não devem ser versionados                            |
| `README.md`                       | Documentação do template                                                                 |

### `setup-dev-env.sh`

O `setup-dev-env.sh` é chamado automaticamente pelo `postCreateCommand` do Dev Container.

Ele é responsável por preparar itens que precisam ser configurados depois que o container é criado, como:

* integração com o `.bashrc`;
* inicialização do ambiente ESP-IDF;
* configuração necessária do Git para os repositórios internos do ESP-IDF;
* preparação do diretório do `ccache`.

O script também pode ser executado novamente:

```bash
esp-setup
```

Ele foi desenvolvido para ser idempotente, permitindo sua reexecução sem duplicar a configuração já existente.

---

## 📦 Dependências Linux

Além do conteúdo fornecido pela imagem oficial ESP-IDF, o template instala explicitamente algumas ferramentas adicionais para desenvolvimento, análise e diagnóstico.

| Pacote            | Uso no ambiente                                         |
| ----------------- | ------------------------------------------------------- |
| `binwalk`         | Inspeção e análise de imagens e arquivos binários       |
| `ca-certificates` | Certificados raiz utilizados em conexões HTTPS/TLS      |
| `ccache`          | Cache de resultados de compilação                       |
| `clang-format`    | Formatação automática de código C/C++                   |
| `clang-tidy`      | Análise estática baseada no Clang                       |
| `cppcheck`        | Análise estática adicional para C/C++                   |
| `curl`            | Requisições HTTP/HTTPS e testes de serviços             |
| `fd-find`         | Busca rápida de arquivos                                |
| `file`            | Identificação de tipos de arquivos e binários           |
| `git`             | Controle de versão                                      |
| `iproute2`        | Ferramentas modernas de diagnóstico de rede             |
| `jq`              | Leitura e manipulação de JSON pelo terminal             |
| `less`            | Visualização paginada de arquivos e logs                |
| `lsof`            | Identificação de arquivos, portas e dispositivos em uso |
| `nano`            | Editor de texto simples para terminal                   |
| `net-tools`       | Ferramentas como `ifconfig`, `netstat`, `route` e `arp` |
| `openssh-client`  | Cliente SSH, incluindo acesso Git via SSH               |
| `picocom`         | Terminal serial leve                                    |
| `pre-commit`      | Framework para execução de hooks antes de commits       |
| `procps`          | Ferramentas para inspeção de processos                  |
| `ripgrep`         | Busca textual rápida através de `rg`                    |
| `sudo`            | Execução pontual de comandos administrativos            |
| `tree`            | Visualização hierárquica de diretórios                  |
| `udev`            | Ferramentas auxiliares para dispositivos Linux          |
| `usbutils`        | Ferramentas USB, incluindo `lsusb`                      |
| `wget`            | Download de arquivos via HTTP/HTTPS                     |
| `zip`             | Criação e manipulação de arquivos ZIP                   |

Alguns desses pacotes podem já existir em determinadas versões da imagem base. Eles são declarados explicitamente quando fazem parte do ambiente esperado pelo template.

### Adicionando novas dependências

Caso um projeto necessite de outro pacote Linux, basta adicioná-lo à instalação existente no:

```text
.devcontainer/Dockerfile
```

Por exemplo:

```dockerfile
RUN apt-get update --quiet \
    && apt-get install -y --no-install-recommends --quiet \
        existing-package \
        new-package
```

Depois da alteração, recrie o container:

```text
Dev Containers: Rebuild Container
```

> ⚠️ **NOTA:** Instalações feitas manualmente dentro de um container não fazem parte da definição do ambiente e podem ser perdidas quando ele for recriado. Dependências necessárias ao projeto devem, preferencialmente, ser declaradas no Dockerfile.

---

## ⚡ ccache

O template utiliza `ccache` para acelerar recompilações.

Quando uma unidade de compilação já foi processada anteriormente com as mesmas entradas relevantes, o `ccache` pode reutilizar o resultado em vez de executar novamente o compilador.

```text
source.c
   │
   ▼
 ccache
   │
   ├── cache hit  → reutiliza o resultado
   │
   └── cache miss → executa o compilador e armazena o resultado
```

O recurso pode ser habilitado (1) ou desabilitado (0) no Dockerfile:

```dockerfile
ARG ENABLE_CCACHE=1 (Habilitado)
```

O tamanho máximo também pode ser definido:

```dockerfile
ARG CCACHE_MAXSIZE=5G
```

O diretório de cache é mantido em um volume Docker persistente. Dessa forma, ele pode continuar disponível mesmo após a reconstrução do Dev Container.

Para consultar as estatísticas:

```bash
ccache --show-stats
```

Para limpar o cache:

```bash
ccache --clear
```

---

## 🧹 Formatação e análise de código

### clang-format

O `clang-format` é utilizado para manter uma formatação consistente no código C/C++.

As regras do projeto ficam no arquivo:

```text
.clang-format
```

na raiz do repositório.

Ele pode controlar, por exemplo:

* indentação;
* posição de chaves;
* espaçamento;
* alinhamento;
* quebra de linhas.

O VS Code está configurado para utilizar o `clang-format` instalado dentro do próprio container, evitando que a formatação dependa da versão instalada no host.

Para C e C++, o projeto também habilita a formatação ao salvar.

O comando pode ser utilizado manualmente:

```bash
clang-format -i main/main.c
```

Durante o `esp-init`, caso exista um `.clang-format`, sua configuração é validada e o código inicial é formatado.

> ⚠️ **NOTA:** O `.clang-format` é opcional. Caso ele não exista, `esp-init` apenas apresenta um warning e continua normalmente.

### clang-tidy e cppcheck

O ambiente também disponibiliza `clang-tidy` e `cppcheck` para análise estática de código C/C++.

Essas ferramentas podem auxiliar na identificação de bugs, construções potencialmente problemáticas e outros problemas de código.

O template apenas disponibiliza as ferramentas. Os checks e políticas de análise podem ser definidos posteriormente de acordo com as necessidades de cada projeto.

---

## 📝 EditorConfig

O arquivo:

```text
.editorconfig
```

define algumas regras básicas de edição de forma independente do editor utilizado.

Entre elas estão:

* UTF-8;
* final de linha LF;
* indentação;
* newline no final dos arquivos;
* tratamento de trailing whitespace.

Isso ajuda a evitar diferenças de formatação quando o mesmo projeto é editado por pessoas utilizando configurações ou editores diferentes.

O VS Code utiliza a extensão EditorConfig para interpretar essas regras, mas outros editores com suporte ao padrão também podem utilizar o mesmo arquivo.

---

## 🧠 IntelliSense e `compile_commands.json`

O IntelliSense precisa conhecer os mesmos parâmetros utilizados durante a compilação do firmware, como:

* diretórios de include;
* defines;
* compilador;
* flags;
* arquivos fonte.

Manter essas informações manualmente no VS Code seria difícil, especialmente em um projeto ESP-IDF.

Por isso, a extensão C/C++ está configurada para utilizar:

```text
/app/build/compile_commands.json
```

Esse arquivo é gerado pelo sistema de build e descreve os comandos reais utilizados para compilar cada unidade do projeto.

O fluxo fica aproximadamente:

```text
ESP-IDF / CMake
      │
      ▼
compile_commands.json
      │
      ▼
VS Code C/C++
      │
      ▼
IntelliSense
```

Assim, recursos como autocomplete, navegação entre definições e resolução de headers conseguem utilizar informações próximas das utilizadas na compilação real.

> ⚠️ **NOTA:** O `compile_commands.json` normalmente só estará disponível depois que o projeto tiver sido configurado ou compilado. Caso o IntelliSense ainda não encontre os headers, execute `idf.py build`.

---

## 🧩 VS Code

O template já inclui configurações e extensões voltadas ao desenvolvimento do firmware.

### Extensões

| Extensão       | Uso                                                |
| -------------- | -------------------------------------------------- |
| ESP-IDF        | Integração oficial da Espressif com o VS Code      |
| C/C++          | IntelliSense, navegação e suporte ao código C/C++  |
| EditorConfig   | Interpreta as regras do `.editorconfig`            |
| Serial Monitor | Monitoramento de interfaces seriais                |
| Hex Editor     | Visualização de arquivos binários                  |
| GitLens        | Informações adicionais sobre histórico Git         |
| Prettier       | Formatação de Markdown, JSON e outros formatos     |
| Error Lens     | Exibição de erros e warnings diretamente no editor |
| TODO Tree      | Organização de marcadores como `TODO` e `FIXME`    |

Caso um projeto necessite de outra extensão, ela pode ser adicionada ao array `extensions` do `devcontainer.json`.

Por exemplo:

```jsonc
"extensions": [ "espressif.esp-idf-extension", "ms-vscode.cpptools", "publisher.extension-name" ]
```

Depois da alteração, a nova extensão fará parte do ambiente de desenvolvimento utilizado pelo projeto.

### Configurações do editor

O `devcontainer.json` contém algumas configurações relacionadas diretamente ao ambiente de desenvolvimento, como:

* terminal utilizado dentro do container;
* integração com `compile_commands.json`;
* configuração do `clang-format`;
* format on save para C/C++;
* exclusão de `build/` das buscas e do file watcher.

Configurações visuais como tema, fonte, tamanho da fonte, ícones e cores não foram incluídas propositalmente.

Essas opções não interferem no funcionamento do projeto e normalmente são preferências individuais de cada desenvolvedor. Mantê-las fora do repositório evita que o template altere desnecessariamente a aparência do VS Code de quem estiver utilizando o projeto.

Quem desejar padronizar ou personalizar essas opções pode utilizar:

```text
VS Code → Settings → User
```

ou criar um:

```text
VS Code Profile
```

Dessa forma, a configuração técnica permanece no projeto enquanto a experiência visual continua sob controle de cada desenvolvedor.

---

## 👤 Usuário e permissões

O ambiente de desenvolvimento utiliza um usuário não-root dentro do container.

Isso é importante principalmente porque o projeto é montado a partir do host. Executar o desenvolvimento normalmente como `root` poderia fazer com que arquivos criados pelo container aparecessem no host pertencendo a:

```text
root:root
```

O Dev Container utiliza `updateRemoteUserUID` para ajudar a alinhar o usuário do container com o usuário do host em sistemas Linux.

O usuário também recebe acesso ao grupo `dialout`, utilizado normalmente por interfaces seriais, além de `sudo` para operações administrativas pontuais dentro do ambiente.

---

## 🔌 Serial, USB e JTAG

O template inclui ferramentas como `picocom`, `lsusb` e `udevadm`, mas o acesso do container ao hardware precisa ser configurado de acordo com o dispositivo utilizado.

No `devcontainer.json` existem exemplos de passagem de interfaces seriais:

```jsonc
"runArgs": [
    // "--device=/dev/ttyUSB0"
    // "--device=/dev/ttyACM0"
]
```

Por exemplo, depois de expor `/dev/ttyUSB0`, é possível utilizar:

```bash
picocom -b 115200 /dev/ttyUSB0
```

Interfaces como ESP-Prog, FTDI, J-Link ou USB-JTAG podem exigir configurações adicionais relacionadas a permissões, grupos, `udev`, device mapping ou hotplug.

> ⚠️ **NOTA:** O template não utiliza `--privileged` como configuração padrão. Essa opção concede ao container acesso muito amplo ao host e normalmente não é necessária apenas para desenvolvimento ESP-IDF.

---

## 🖥️ Terminal externo

O ambiente não depende exclusivamente do terminal integrado do VS Code.

É possível utilizar um terminal no host e entrar no container com:

```bash
docker exec -it <container> bash
```

Isso permite, por exemplo, continuar utilizando configurações pessoais de:

```text
Alacritty
tmux
zsh
Starship
```

no host sem adicioná-las ao ambiente compartilhado pelo projeto.

Ao iniciar um Bash interativo dentro do container, a configuração técnica do template disponibiliza normalmente:

```text
idf.py
esp-init
esp-info
esp-setup
```

---

## 🧯 Troubleshooting

### `idf.py: command not found`

Abra um novo terminal dentro do container ou execute:

```bash
esp-setup
```

O ambiente ESP-IDF é carregado através de:

```text
.devcontainer/config/bashrc.sh
```

### `fatal: detected dubious ownership`

Alguns repositórios internos da imagem ESP-IDF podem possuir ownership diferente do usuário utilizado no Dev Container.

O `setup-dev-env.sh` registra os diretórios necessários como `safe.directory`.

Caso o problema apareça:

```bash
esp-setup
```

É possível verificar os diretórios registrados com:

```bash
git config --global --get-all safe.directory
```

> ⚠️ **NOTA:** O template não utiliza `safe.directory '*'`. Apenas os diretórios relacionados à instalação do ESP-IDF são adicionados.

### IntelliSense não encontra headers

Verifique se existe:

```text
build/compile_commands.json
```

Caso ainda não exista:

```bash
idf.py build
```

### Porta serial não aparece no container

Primeiro verifique se a porta existe no host:

```bash
ls -l /dev/ttyUSB*
ls -l /dev/ttyACM*
```

Depois verifique dentro do container.

Se o dispositivo existir apenas no host, configure seu encaminhamento no `devcontainer.json` e recrie o container.

### Alterações do ambiente não foram aplicadas

Mudanças no Dockerfile, mounts, usuário ou configurações do Dev Container podem exigir uma reconstrução.

Utilize:

```text
Dev Containers: Rebuild Container
```

Caso seja necessário descartar também o cache de build da imagem:

```text
Dev Containers: Rebuild Container Without Cache
```

---

## 🧭 Filosofia do projeto

A ideia principal deste template é manter as ferramentas específicas do desenvolvimento ESP-IDF fora do sistema operacional host.

```text
                 Host
                  │
          Docker + VS Code
                  │
                  ▼
        ESP-IDF Dev Container
                  │
      ┌───────────┼───────────┐
      │           │           │
      ▼           ▼           ▼
  Toolchain    Dev Tools    Analysis
      │           │           │
      └───────────┼───────────┘
                  │
                  ▼
               Firmware
```

Se uma ferramenta for necessária para desenvolver o projeto, ela pode ser incorporada à definição do ambiente e compartilhada junto com o repositório.

Assim, ao utilizar o projeto em outra máquina ou por outro desenvolvedor, não é necessário reconstruir manualmente todo o ambiente de desenvolvimento: basta criar o mesmo Dev Container.
