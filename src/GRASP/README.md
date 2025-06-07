# GRASP Quick Usage Guide

## **Your New Organized Structure**

```
GRASP/
├── core/         # Algorithm implementations (GRASP.m, GRASPOptimized.m, etc.)
├── analysis/     # Analysis functions (node frequency, phase analysis, etc.)
├── runners/      # Execution scripts (runGRASP.m, etc.)
├── utilities/    # Helper functions
├── exports/      # Export functions
├── lib/          # Library functions
├── output/       # Execution logs
├── plots/        # Generated visualizations  
├── results/      # Saved results
├── main.m           # MAIN ENTRY POINT
└── README.md        # Detailed documentation
```

## **How to Run Everything**

### **1. Quick Start (Interactive Menu)**
```matlab
cd src/GRASP
main()
```

### **2. Run Everything with Optimized GRASP**
```matlab
main('optimized', 'analysis')
```

### **3. Analyze Existing Results Only (Fast)**
```matlab
main('existing')
```

### **4. Run Fresh Analysis**
```matlab
main('fresh')
```

## **Terminal Usage**

```bash
cd "/path/to/mei-so-2/src/GRASP"

# Quick analysis of existing results
matlab -nodisplay -nosplash -r "main('existing'); exit"

# Full optimized run with analysis
matlab -nodisplay -nosplash -r "main('optimized', 'analysis'); exit"

# Interactive menu
matlab -nodisplay -nosplash -r "main(); exit"
```

## **Specific Analysis Functions**

| Command | What it does | Time |
|---------|--------------|------|
| `main('existing')` | Analyze saved results | 30 seconds |
| `main('phase')` | Phase contribution analysis | 2-3 minutes |
| `main('nodes')` | Node frequency analysis | 2-3 minutes |
| `main('comparison')` | Compare implementations | 3-5 minutes |
| `main('sensitivity')` | Parameter sensitivity | 15-20 minutes |

## **Check Organization**

```matlab
checkOrganization()  % Verify all files are in place
```

## **What You Get**

### **Automatic Outputs:**
- **Plots** → `plots/` directory
- **Results** → `results/` directory  
- **Logs** → `output/` directory

### **Key Analysis:**
- Node frequency analysis
- Phase contribution analysis
- Implementation comparison
- Parameter sensitivity
- Solution quality statistics

## **Recommended Workflow**

### **First Time:**
```matlab
main('optimized', 'analysis')  % Full run (~8-10 minutes)
```

### **After Changes:**
```matlab
main('existing')  # Quick analysis (~30 seconds)
```

### **Deep Analysis:**
```matlab
main('sensitivity')  # Parameter tuning (~20 minutes)
```