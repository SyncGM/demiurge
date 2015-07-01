package com.github.sesvxace.demiurge;

import java.awt.Graphics;
import java.awt.RenderingHints;

public class ListBackground extends javax.swing.DefaultListCellRenderer {
  private final java.awt.Color alternateColor =
                                              new java.awt.Color(228, 236, 242);
  private final java.awt.Color selectedColorOne =
                                                new java.awt.Color(0, 100, 200);
  private final java.awt.Color selectedColorTwo =
                                                new java.awt.Color(0, 163, 251);
  
  @Override
  protected void paintComponent(Graphics g) {
    if (getBackground().equals(selectedColorOne)) {
      java.awt.Graphics2D g2 = (java.awt.Graphics2D) g;
      g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                                             RenderingHints.VALUE_ANTIALIAS_ON);
      java.awt.GradientPaint p = new java.awt.GradientPaint(0, 0,
                            selectedColorOne, 0, getHeight(), selectedColorTwo);
      g2.setPaint(p);
      g2.fillRect(0, 0, getWidth(), getHeight());
    }
    super.paintComponent(g);
  }
  
  @Override
  public java.awt.Component getListCellRendererComponent(javax.swing.JList list,
            Object value, int index, boolean isSelected, boolean cellHasFocus) {
    super.getListCellRendererComponent(list, value, index, isSelected,
                                                                  cellHasFocus);
    if (!isSelected) {
      setForeground(java.awt.Color.black);
      if (index % 2 == 1) setBackground(alternateColor);
      setOpaque(true);
    } else if (isSelected) {
      setForeground(java.awt.Color.white);
      setBackground(selectedColorOne);
      setOpaque(false);
    }
    return this;
  }
}