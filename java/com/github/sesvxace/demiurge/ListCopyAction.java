package com.github.sesvxace.demiurge;

import java.awt.event.ActionEvent;
import javax.swing.JList;

public class ListCopyAction extends javax.swing.AbstractAction {
  private final DataSplitPane owner;
  
  public ListCopyAction(DataSplitPane owner) {
    this.owner = owner;
  }

  @Override
  public void actionPerformed(ActionEvent e) {
    JList list = (JList) e.getSource();
    String s = (String) list.getSelectedValue();
    owner.setCopy(s);
  }
  
}