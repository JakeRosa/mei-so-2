# Problema de Seleção de Nós Servidores (SNS)

## Descrição do Projeto

Este projeto implementa três abordagens algorítmicas para resolver o **Problema de Seleção de Nós Servidores (Server Node Selection - SNS)** numa rede de 200 nós. O objetivo é selecionar 12 nós para atuarem como servidores/controladores, minimizando a distância média dos nós aos servidores mais próximos, respeitando restrições de conectividade.

## Problema de Otimização

### Definição Formal
- **Rede**: Grafo com 200 nós e 250 arestas ponderadas
- **Variável de Decisão**: Selecionar exatamente n=12 nós como servidores
- **Função Objetivo**: Minimizar a distância média (avgSP) de cada nó ao servidor mais próximo
- **Restrição Principal**: A distância máxima entre qualquer par de servidores (maxSP) não pode exceder Cmax=1000

### Ficheiros de Dados
- `data/Nodes200.txt`: Coordenadas (x,y) dos 200 nós
- `data/Links200.txt`: 250 ligações da rede
- `data/L200.txt`: Matriz de adjacência 200x200 com pesos das arestas

## Algoritmos Implementados

### 1. GRASP (Greedy Randomized Adaptive Search Procedure)
- **Tipo**: Meta-heurística híbrida
- **Localização**: `src/GRASP/`
- **Características**: Combina construção gulosa aleatorizada com busca local
- **Melhor Solução**: avgSP = 143.085

### 2. GA (Algoritmo Genético)
- **Tipo**: Meta-heurística evolutiva
- **Localização**: `src/GA/`
- **Características**: Evolução populacional com seleção, cruzamento e mutação
- **Melhor Solução**: avgSP ≈ 143-149

### 3. ILP (Programação Linear Inteira)
- **Tipo**: Método exato
- **Localização**: `src/ILP/`
- **Características**: Formulação matemática resolvida com lp_solve
- **Solução Ótima**: avgSP = 145.085

## Estrutura do Projeto

```
mei-so-2/
├── data/                   # Ficheiros de dados da rede
├── src/
│   ├── GRASP/             # Implementação GRASP
│   │   ├── core/          # Algoritmos principais
│   │   ├── analysis/      # Scripts de análise
│   │   ├── plots/         # Gráficos gerados
│   │   └── results/       # Resultados guardados
│   ├── GA/                # Implementação GA
│   │   ├── core/          # Algoritmos principais
│   │   ├── analysis/      # Scripts de análise
│   │   ├── plots/         # Gráficos gerados
│   │   └── results/       # Resultados guardados
│   └── ILP/               # Implementação ILP
│       ├── plots/         # Gráficos gerados
│       └── results/       # Resultados guardados
├── loadData.m             # Carregamento dos dados
├── PerfSNS.m              # Avaliação de soluções
└── plotNetworkSolution.m  # Visualização de soluções
```

## Como Executar

### Pré-requisitos
- MATLAB R2020a ou superior
- lp_solve (para ILP)

### Execução Rápida

1. **GRASP**:
```matlab
cd src/GRASP
main
```

2. **GA**:
```matlab
cd src/GA
main
```

3. **ILP**:
```matlab
cd src/ILP
generate_lp
% Executar lp_solve externamente
run_ilp_plots
```

### Comparação de Algoritmos
```matlab
plot_grasp_vs_ga  % Compara GRASP vs GA
```

## Funções Principais

### `loadData()`
Carrega os ficheiros de dados e cria o grafo da rede.

### `PerfSNS(nodesFile, linksFile, LFile, nodes_servers, Cmax, Dist)`
Avalia uma solução calculando:
- `avgSP`: Distância média aos servidores
- `maxSP`: Distância máxima entre servidores
- `feasible`: Se a solução respeita as restrições

### `plotNetworkSolution(g, nodes_servers, avgSP, maxSP)`
Visualiza a rede com os servidores selecionados.

## Resultados Principais

| Algoritmo | avgSP | maxSP | Tempo | Observações |
|-----------|-------|-------|-------|-------------|
| ILP | 145.085 | 923 | ~minutos | Solução ótima garantida |
| GRASP | 143.085 | 960 | ~segundos | Melhor solução encontrada |
| GA | 143-149 | <1000 | ~segundos | Resultados variáveis |

## Análises Disponíveis

- **Análise de Parâmetros**: Sensibilidade dos algoritmos aos parâmetros
- **Análise de Convergência**: Evolução da qualidade ao longo do tempo
- **Análise de Fases**: Contribuição de cada fase (para GRASP)
- **Comparações**: Desempenho relativo entre algoritmos

## Autores

Projeto desenvolvido no âmbito da UC de Sistemas de Otimização - MEI

## Licença

Este projeto está licenciado sob a Licença MIT - ver ficheiro LICENSE para detalhes.