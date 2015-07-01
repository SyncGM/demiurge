package com.github.sesvxace.demiurge;

import javax.swing.table.DefaultTableModel;

public class PluginTableModel extends DefaultTableModel {
  
  public PluginTableModel(Object[] columnNames) {
    super(columnNames, 0);
  }
  
  @Override
  public Class getColumnClass(int column) {
    if (column == 0) return Boolean.class;
    else return String.class;
  }
  
  @Override
  public boolean isCellEditable(int row, int col) {
    if (col == 1) return false;
    return true;
  }
}