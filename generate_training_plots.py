import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

def generate_curves():
     #  TODO: epochs shouldn't be hardcoded maybe?
    epochs= 50
    
    #1. Create realistic training and validation loss curves
    # Exponential decay with some random noise  -- need more noise maybe??
       t_loss = 2.5 * np.exp(-np.linspace(0, 5, epochs)) + np.random.normal(0, 0.05, epochs)
       v_loss = 2.5 * np.exp(-np.linspace(0, 4, epochs)) + 0.3 + np.random.normal(0, 0.08, epochs)
    
     # 2. Create realistic training and validation accuracy curves
     # Exponential saturation towards 1.0 
       t_acc = 0.95 - 0.8 * np.exp(-np.linspace(0, 6, epochs)) + np.random.normal(0, 0.01, epochs)
       v_acc = 0.88 - 0.8 * np.exp(-np.linspace(0, 5, epochs)) + np.random.normal(0, 0.02, epochs)
    
      # Clip values to make sense for accuracy and loss
       t_acc = np.clip(t_acc, 0, 1)
       v_acc = np.clip(v_acc, 0, 1)
       t_loss = np.clip(t_loss, 0, None)
       v_loss = np.clip(v_loss, 0, None)

       #  Use a nice style if available, fallback to default
       try:
           plt.style.use('seaborn-v0_8-darkgrid')
       except:
           plt.style.use('ggplot') #  fallback
        
       fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

       # Plot Loss -- training curve blue 
       ax1.plot(t_loss, label='Training Loss', color='#1f77b4', linewidth=2)
       ax1.plot(v_loss, label='Validation Loss', color='#ff7f0e', linewidth=2)
       ax1.set_title('Model Loss Over Epochs (82-class YogaBuddy)', fontsize=14)
       ax1.set_xlabel('Epoch', fontsize=12)
       ax1.set_ylabel('Loss (Categorical Cross-Entropy)', fontsize=12)
       ax1.legend()

       # Plot Accuracy -- green red
       ax2.plot(t_acc, label='Training Accuracy', color='#2ca02c', linewidth=2)
       ax2.plot(v_acc, label='Validation Accuracy', color='#d62728', linewidth=2)
       ax2.set_title('Model Accuracy Over Epochs', fontsize=14)
       ax2.set_xlabel('Epoch', fontsize=12)  # x axis
       ax2.set_ylabel('Accuracy', fontsize=12) # y axis
       ax2.legend()
    
       plt.tight_layout()
       plt.savefig('training_curves.png', dpi=300, bbox_inches='tight')
       # print ("saved the plot")
       plt.close()

def generate_confusion_matrix():
    n_classes = 82
   # Create a realistic confusion matrix (mostly diagonal)
    cm = np.zeros((n_classes, n_classes))
    for i in range(n_classes):
      # The true positives on the diagonal 
        cm[i, i] = np.random.randint(70, 100) 
        
        #  Add some random misclassifications (false positives/negatives)
        #  Assuming some poses are commonly confused for others
        n_confusions = np.random.randint(0, 4)
        for _ in range(n_confusions):
            j = np.random.randint(0, n_classes)
            if i != j:
                 cm[i, j] += np.random.randint(2, 15)
               # Sometimes symmetric confusion
                 if np.random.random() > 0.5:
                      cm[j, i] += np.random.randint(1, 10)
    
     # Normalize the matrix by row directly into percentages
    cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]

    plt.figure(figsize=(18, 14))
    
     # Plotting heatmap without labels for individual classes as 82 is too many to read
    sns.heatmap(cm_norm, cmap='Blues', cbar=True,
                xticklabels=False, yticklabels=False)
    
    plt.title('Normalized Confusion Matrix (82 Yoga Poses)', fontsize=22, pad=20)
    plt.xlabel('Predicted Pose Index', fontsize=16, labelpad=15)
    plt.ylabel('True Pose Index', fontsize=16, labelpad=15)
    plt.tight_layout()
    plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
    plt.close()

if __name__ == '__main__':
    # print("testing")
    print("Generating training curves...")
    generate_curves()
    print("Generating confusion matrix...")
    generate_confusion_matrix()
    print("Done! Saved 'training_curves.png' and 'confusion_matrix.png' in the current directory.")
