package com.github.sesvxace.demiurge;

import javax.swing.text.BadLocationException;

public class TextField extends javax.swing.JTextField {
  private int mode;
  
  public TextField() {
    super();
    mode = 0;
  }
  
  public TextField(String value) {
    super(value);
    mode = 0;
  }

  @Override
  protected javax.swing.text.Document createDefaultModel() {
    return new ModularDocument();
  }
  
  public Object getValue() {
    if (mode == 0) return getText();
    try {
      if (mode == 1) return Integer.parseInt(getText());
      else if (mode == 2) return Double.parseDouble(getText());
    } catch (Exception e) { return null; }
    return null;
  }

  @Override
  public boolean isValid() {
    if (mode == 0) return true;
    try {
      if (mode == 1) { Integer.parseInt(getText()); }
      else if (mode == 2) { Double.parseDouble(getText()); }
      return true;
    } catch (Exception e) { return false; }
  }
  
  public void setMode(int mode) {
    this.mode = mode;
    ((ModularDocument) getDocument()).setMode(mode);
  }
  
  public void setMode(String m) {
    if (m.equalsIgnoreCase("string")) {
      mode = 0;
      ((ModularDocument) getDocument()).setMode(0);
    } else if (m.equalsIgnoreCase("integer") || m.equalsIgnoreCase("int")) {
      mode = 1;
      ((ModularDocument) getDocument()).setMode(1);
    } else if (m.equalsIgnoreCase("real") || m.equalsIgnoreCase("float")) { 
      mode = 2;
      ((ModularDocument) getDocument()).setMode(2);
    }
  }
  
  class ModularDocument extends javax.swing.text.PlainDocument {
    private int mode;
    
    @Override
    public void insertString(int offset, String string,
                                       javax.swing.text.AttributeSet attributes)
                                  throws javax.swing.text.BadLocationException {
      if (string == null) return;
      String contents = getText(0, getLength());
      contents = contents.substring(0, offset) + string +
                                                     contents.substring(offset);
      try {
        if (this.mode == 1) Integer.parseInt(contents + "0");
        else if (this.mode == 2) Double.parseDouble(contents + "0");
        super.insertString(offset, string, attributes);
      } catch (NumberFormatException | BadLocationException e) {}
    }
    
    public void setMode(int mode) {
      this.mode = mode;
    }
  }
  
}
