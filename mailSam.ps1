$From = "shivam25gupta96@gmail.com"
$To = "shiv250396@gmail.com"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
$Username = "shivam25gupta96@gmail.com"
$Password = "csdoyktbzcdmjlac"
$subject = "Email Subject"
$body = "Insert body text here"

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);

$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$smtp.Send($From, $To, $subject, $body);