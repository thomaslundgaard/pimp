from PyQt4 import QtGui, QtCore
from adminDialog_ui import Ui_AdminDialog

class AdminDialog(QtGui.QDialog):
    def __init__ (self,  parent = None):
        QtGui.QDialog.__init__ (self,  parent)
        self.ui = Ui_AdminDialog ()
        self.ui.setupUi (self)
        self.ui.infoLabel.hide()
        self.resize(-1, -1)
        self.ui.pwdEdit.setFocus()
    
    def checkPwd(self):
         if str(self.ui.pwdEdit.text()) == "kkk":
            self.close()
            return True
         else:
            self.ui.pwdEdit.clear()
            self.ui.infoLabel.setText("Invalid password - please try again:")
            self.ui.infoLabel.show()
            return False

    def minimizeApp(self):
        print "mini"
        if self.checkPwd():
            self.parent().isFullscreen = False
            self.parent().showMinimized()
        
    def quitApp(self):
        print "quit"
        if self.checkPwd():
            QtGui.qApp.quit()

    def cancelDialog(self):
        self.close()
