package com.github.sesvxace.demiurge;

import java.awt.event.ActionEvent;
import javax.swing.AbstractAction;
import javax.swing.Action;
import javax.swing.undo.CannotRedoException;
import javax.swing.undo.UndoManager;

public class RedoAction extends AbstractAction {
  private UndoManager undoManager;
  private UndoAction undoAction;
  
  public RedoAction(UndoManager manager) {
    super("Redo");
    setEnabled(false);
    undoManager = manager;
  }

  @Override
  public void actionPerformed(ActionEvent e) {
    try {
      undoManager.redo();
    } catch (CannotRedoException ex) {}
    update();
    undoAction.update();
  }
  
  public void clear() {
    undoManager = null;
    undoAction = null;
  }
  
  public void setUndoAction(UndoAction undo) {
    undoAction = undo;
  }

  protected void update() {
    if (undoManager.canRedo()) {
      setEnabled(true);
      putValue(Action.NAME, undoManager.getUndoPresentationName());
    } else {
      setEnabled(false);
      putValue(Action.NAME, "Redo");
    }
  }
}