var app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
  app.displayDialog('Do you want to initialize settings?');
  var ret = app.displayDialog('Enter new pass phrase:', {
    defaultAnswer: '',
    hiddenAnswer: true
  });
  ret.textReturned;
} catch (e) {
  '';
}
