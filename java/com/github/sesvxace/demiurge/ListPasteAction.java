package com.github.sesvxace.demiurge;

import java.awt.event.ActionEvent;
import javax.swing.JList;

public class ListPasteAction extends javax.swing.AbstractAction {
  private final DataSplitPane owner;
  
  public ListPasteAction(DataSplitPane owner) {
    this.owner = owner;
  }

  @Override
  public void actionPerformed(ActionEvent e) {
    JList list = (JList) e.getSource();
    int i = list.getSelectedIndex();
    owner.pasteAtIndex(i);
  }
  
}
