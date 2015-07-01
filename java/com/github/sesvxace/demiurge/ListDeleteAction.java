package com.github.sesvxace.demiurge;

import java.awt.event.ActionEvent;
import javax.swing.DefaultListModel;
import javax.swing.JList;

public class ListDeleteAction extends javax.swing.AbstractAction {

  @Override
  public void actionPerformed(ActionEvent e) {
    JList list = (JList) e.getSource();
    int i = list.getSelectedIndex();
    DefaultListModel model = ((DefaultListModel) list.getModel());
    if (!list.getSelectedValue().equals(" ")) {
      model.remove(i);
      while (model.getSize() < 5) model.add(model.getSize(), " ");
    }
  } 
}