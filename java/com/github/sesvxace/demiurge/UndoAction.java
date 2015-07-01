package com.github.sesvxace.demiurge;

import java.awt.event.ActionEvent;
import javax.swing.AbstractAction;
import javax.swing.Action;
import javax.swing.undo.CannotUndoException;
import javax.swing.undo.UndoManager;

public class UndoAction extends AbstractAction {
  private UndoManager undoManager;
  private RedoAction redoAction;
  
  public UndoAction(UndoManager manager) {
    super("Undo");
    setEnabled(false);
    undoManager = manager;
  }

  @Override
  public void actionPerformed(ActionEvent e) {
    try {
      undoManager.undo();
    } catch (CannotUndoException ex) {}
    update();
    redoAction.update();
  }
  
  public void clear() {
    undoManager = null;
    redoAction = null;
  }
  
  public void setRedoAction(RedoAction redo) {
    redoAction = redo;
  }

  protected void update() {
    if (undoManager.canUndo()) {
      setEnabled(true);
      putValue(Action.NAME, undoManager.getUndoPresentationName());
    } else {
      setEnabled(false);
      putValue(Action.NAME, "Undo");
    }
  }
}