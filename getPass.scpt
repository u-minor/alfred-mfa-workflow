var app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
  var ret = app.displayDialog('Enter pass phrase:', {
    defaultAnswer: '',
    hiddenAnswer: true
  });
  ret.textReturned;
} catch (e) {
  '';
}
