using System.Net;
using System.Net.Mail;
using Microsoft.AspNetCore.Identity.UI.Services;

namespace TeamManage.Services.Email
{
    public class EmailSender : IEmailSender
    {
        private readonly IConfiguration _configuration;
        public EmailSender(IConfiguration configuration) => _configuration = configuration;
    

        public Task SendEmailAsync(string email, string subject, string htmlMessage){
            var client = new SmtpClient("smtp.gmail.com", 587)
            {
                Credentials = new NetworkCredential(
                    _configuration["Email:Account"],
                    _configuration["Email:AppPassword"]
                ),
                EnableSsl = true
            };

            var message = new MailMessage
            {
                From = new MailAddress(_configuration["Email:Account"]),
                Subject = subject,
                Body = htmlMessage,
                IsBodyHtml = true
            };

            message.To.Add(email);
            return client.SendMailAsync(message);
        }
    }
}
