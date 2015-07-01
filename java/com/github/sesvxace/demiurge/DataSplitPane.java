package com.github.sesvxace.demiurge;

import javax.swing.JSplitPane;

public abstract class DataSplitPane extends JSplitPane {
  
  public DataSplitPane() {
    super(HORIZONTAL_SPLIT);
  }
  
  public abstract void setCopy(String n);
  public abstract void pasteAtIndex(int n);
}