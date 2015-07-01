package com.github.sesvxace.demiurge;

import java.awt.event.KeyEvent;
import java.awt.event.WindowEvent;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.event.WindowListener;
import java.io.File;
import javax.swing.JCheckBoxMenuItem;
import javax.swing.JMenu;
import javax.swing.JMenuItem;

public abstract class MainWindow extends javax.swing.JFrame {
  private final CloseHandler closeListener;
  private final JFileChooser projectSelection;
  private String project;
  private String projectDirectory;
  private boolean modified;

  public MainWindow() {
    initComponents();
    closeListener = new CloseHandler();
    addWindowListener(closeListener);
    modified = false;
    fileMenu.setMnemonic(KeyEvent.VK_F);
    menuItemOpen.setMnemonic(KeyEvent.VK_O);
    menuItemSave.setMnemonic(KeyEvent.VK_S);
    menuItemClose.setMnemonic(KeyEvent.VK_C);
    menuItemExit.setMnemonic(KeyEvent.VK_X);
    optionsMenu.setMnemonic(KeyEvent.VK_O);
    helpMenu.setMnemonic(KeyEvent.VK_H);
    toolMenu.setMnemonic(KeyEvent.VK_T);
    menuItemCreatePlugin.setMnemonic(KeyEvent.VK_C);
    menuItemSelectPlugins.setMnemonic(KeyEvent.VK_P);
    menuItemAbout.setMnemonic(KeyEvent.VK_A);
    projectSelection = new JFileChooser();
    projectSelection.setAcceptAllFileFilterUsed(false);
    projectSelection.addChoosableFileFilter(new FileNameExtensionFilter(
                                    "RPGVXAce Project (*.rvproj2)", "rvproj2"));
  }

  @SuppressWarnings("unchecked")
  // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
  private void initComponents() {

    tabContainer = new javax.swing.JTabbedPane();
    menuBar = new javax.swing.JMenuBar();
    fileMenu = new javax.swing.JMenu();
    menuItemOpen = new javax.swing.JMenuItem();
    menuItemSave = new javax.swing.JMenuItem();
    menuItemClose = new javax.swing.JMenuItem();
    jSeparator1 = new javax.swing.JPopupMenu.Separator();
    menuItemExit = new javax.swing.JMenuItem();
    optionsMenu = new javax.swing.JMenu();
    menuItemAutoUpdate = new javax.swing.JCheckBoxMenuItem();
    toolMenu = new javax.swing.JMenu();
    menuItemCreatePlugin = new javax.swing.JMenuItem();
    menuItemSelectPlugins = new javax.swing.JMenuItem();
    helpMenu = new javax.swing.JMenu();
    menuItemAbout = new javax.swing.JMenuItem();

    setDefaultCloseOperation(javax.swing.WindowConstants.DO_NOTHING_ON_CLOSE);
    setTitle("Demiurge");
    setPreferredSize(new java.awt.Dimension(640, 480));
    getContentPane().setLayout(new java.awt.GridLayout(1, 0));
    getContentPane().add(tabContainer);

    fileMenu.setText("File");

    menuItemOpen.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_O, java.awt.event.InputEvent.CTRL_MASK));
    menuItemOpen.setText("Open Project");
    menuItemOpen.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemOpenActionPerformed(evt);
      }
    });
    fileMenu.add(menuItemOpen);

    menuItemSave.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, java.awt.event.InputEvent.CTRL_MASK));
    menuItemSave.setText("Save Project");
    menuItemSave.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemSaveActionPerformed(evt);
      }
    });
    fileMenu.add(menuItemSave);

    menuItemClose.setText("Close Project");
    menuItemClose.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemCloseActionPerformed(evt);
      }
    });
    fileMenu.add(menuItemClose);
    fileMenu.add(jSeparator1);

    menuItemExit.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_X, java.awt.event.InputEvent.CTRL_MASK));
    menuItemExit.setText("Exit Program");
    menuItemExit.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemExitActionPerformed(evt);
      }
    });
    fileMenu.add(menuItemExit);

    menuBar.add(fileMenu);

    optionsMenu.setText("Options");

    menuItemAutoUpdate.setSelected(true);
    menuItemAutoUpdate.setText("Auto-Update Demiurge");
    menuItemAutoUpdate.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemAutoUpdateActionPerformed(evt);
      }
    });
    optionsMenu.add(menuItemAutoUpdate);

    menuBar.add(optionsMenu);

    toolMenu.setText("Tools");

    menuItemCreatePlugin.setText("Create Plugin");
    menuItemCreatePlugin.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemCreatePluginActionPerformed(evt);
      }
    });
    toolMenu.add(menuItemCreatePlugin);

    menuItemSelectPlugins.setText("Select Plugins");
    menuItemSelectPlugins.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemSelectPluginsActionPerformed(evt);
      }
    });
    toolMenu.add(menuItemSelectPlugins);

    menuBar.add(toolMenu);

    helpMenu.setText("Help");

    menuItemAbout.setText("About");
    menuItemAbout.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        menuItemAboutActionPerformed(evt);
      }
    });
    helpMenu.add(menuItemAbout);

    menuBar.add(helpMenu);

    setJMenuBar(menuBar);

    pack();
  }// </editor-fold>//GEN-END:initComponents

  protected abstract void createPlugin(Object[] data);
  
  private void menuItemOpenActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemOpenActionPerformed
    projectSelection.setCurrentDirectory(new File(projectDirectory));
    if (projectSelection.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
      project = projectSelection.getSelectedFile().getParent();
      projectDirectory = project;
      loadProject();
    }
  }//GEN-LAST:event_menuItemOpenActionPerformed

  private void menuItemSaveActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemSaveActionPerformed
    saveProject();
  }//GEN-LAST:event_menuItemSaveActionPerformed

  private void menuItemCloseActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemCloseActionPerformed
    closeProject();
  }//GEN-LAST:event_menuItemCloseActionPerformed

  private void menuItemExitActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemExitActionPerformed
    promptForExit();
  }//GEN-LAST:event_menuItemExitActionPerformed

  private void menuItemAboutActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemAboutActionPerformed
    AboutDialog about = new AboutDialog(this, true);
    about.pack();
    about.setLocationRelativeTo(this);
    about.setVisible(true);
  }//GEN-LAST:event_menuItemAboutActionPerformed

  private void menuItemSelectPluginsActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemSelectPluginsActionPerformed
    selectPlugins();
  }//GEN-LAST:event_menuItemSelectPluginsActionPerformed

  private void menuItemAutoUpdateActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemAutoUpdateActionPerformed
    setAutoUpdate();
  }//GEN-LAST:event_menuItemAutoUpdateActionPerformed

  private void menuItemCreatePluginActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_menuItemCreatePluginActionPerformed
    PluginCreatorDialog creator = new PluginCreatorDialog(this, true);
    creator.setVisible(true);
    createPlugin(creator.getPlugin());
  }//GEN-LAST:event_menuItemCreatePluginActionPerformed
  
  public abstract void closeProject();
  
  public JMenu getFileMenu() {
    return fileMenu;
  }
  
  public JMenu getHelpMenu() {
    return helpMenu;
  }
  
  public JMenuItem getMenuItemAbout() {
    return menuItemAbout;
  }
  
  public JMenuItem getMenuItemAutoUpdate() {
    return menuItemAutoUpdate;
  }
  
  public JMenuItem getMenuItemClose() {
    return menuItemClose;
  }
  
  public JMenuItem getMenuItemCreatePlugin() {
    return menuItemCreatePlugin;
  }
  
  public JMenuItem getMenuItemExit() {
    return menuItemExit;
  }
  
  public JMenuItem getMenuItemSave() {
    return menuItemSave;
  }
  
  public JMenuItem getMenuItemSelectPlugins() {
    return menuItemSelectPlugins;
  }
  
  public boolean getModified() {
    return modified;
  }
  
  public JMenu getOptionsMenu() {
    return optionsMenu;
  }
  
  public String getProject() {
    return project;
  }
  
  public String getProjectDirectory() {
    return projectDirectory;
  }
  
  public javax.swing.JTabbedPane getTabContainer() {
    return tabContainer;
  }
  
  public JMenu getToolMenu() {
    return toolMenu;
  }
  
  public boolean isModified() {
    return modified;
  }
  
  public abstract String projectName();
  
  private void promptForExit() {
    if (isModified()) {
        int r = JOptionPane.showConfirmDialog(this,
                         "Save changes to " + projectName() + "?", "Demiurge",
                                              JOptionPane.YES_NO_CANCEL_OPTION);
        if (r == JOptionPane.YES_OPTION) {
          saveProject();
          dispose();
          System.exit(0);
        } else if (r == JOptionPane.NO_OPTION) {
          dispose();
          System.exit(0);
        }
      } else {
        dispose();
        System.exit(0);
      }
  }
  
  protected abstract void loadProject();
  
  protected abstract void saveProject();
  
  protected abstract void selectPlugins();
  
  protected abstract void setAutoUpdate();
  
  public void setModified(boolean modified) {
    this.modified = modified;
  }
  
  public void setProject(String project) {
    this.project = project;
  }
  
  public void setProjectDirectory(String projectDirectory) {
    this.projectDirectory = projectDirectory;
  }
    

  // Variables declaration - do not modify//GEN-BEGIN:variables
  private javax.swing.JMenu fileMenu;
  private javax.swing.JMenu helpMenu;
  private javax.swing.JPopupMenu.Separator jSeparator1;
  private javax.swing.JMenuBar menuBar;
  private javax.swing.JMenuItem menuItemAbout;
  private javax.swing.JCheckBoxMenuItem menuItemAutoUpdate;
  private javax.swing.JMenuItem menuItemClose;
  private javax.swing.JMenuItem menuItemCreatePlugin;
  private javax.swing.JMenuItem menuItemExit;
  private javax.swing.JMenuItem menuItemOpen;
  private javax.swing.JMenuItem menuItemSave;
  private javax.swing.JMenuItem menuItemSelectPlugins;
  private javax.swing.JMenu optionsMenu;
  private javax.swing.JTabbedPane tabContainer;
  private javax.swing.JMenu toolMenu;
  // End of variables declaration//GEN-END:variables

  private class CloseHandler implements WindowListener {
    @Override
    public void windowOpened(WindowEvent e) {}

    @Override
    public void windowClosing(WindowEvent e) {
      ((MainWindow) e.getWindow()).promptForExit();
    }

    @Override
    public void windowClosed(WindowEvent e) {}

    @Override
    public void windowIconified(WindowEvent e) {}

    @Override
    public void windowDeiconified(WindowEvent e) {}

    @Override
    public void windowActivated(WindowEvent e) {}

    @Override
    public void windowDeactivated(WindowEvent e) {}
  }
}