package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.request.EmailSendRequestDto;
import com.ssafy.ollana.auth.dto.request.EmailVerifyRequestDto;
import com.ssafy.ollana.auth.exception.EmailCodeExpiredException;
import com.ssafy.ollana.auth.exception.InvalidEmailCodeException;
import com.ssafy.ollana.auth.exception.MailSendException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class MailService {

    @Value("${spring.mail.username}")
    private String sender;

    private final JavaMailSender mailSender;
    private final RedisTemplate<String, String> redisTemplate;

    public void sendMail(EmailSendRequestDto request) {
        String recipientEmail = request.getEmail();
        int code = createCode();
        MimeMessage message = createMail(recipientEmail, code);

        try {
            mailSender.send(message);
        } catch (MailSendException e) {
            log.error("메일 전송 중 오류 발생", e);
            throw new MailSendException();
        }

        // redis에 인증번호 저장
        redisTemplate.opsForValue().set(
                "emailCode:" + recipientEmail,
                String.valueOf(code),
                Duration.ofMinutes(5)
        );
    }

    public void verifyCode(EmailVerifyRequestDto request) {
        String recipientEmail = request.getEmail();
        String inputCode = request.getCode();

        String key = "emailCode:" + recipientEmail;
        String savedCode = redisTemplate.opsForValue().get(key);

        if (savedCode == null) {
            throw new EmailCodeExpiredException();
        }

        if (!savedCode.equals(inputCode)) {
            throw new InvalidEmailCodeException();
        }

        redisTemplate.delete(key); // 인증 성공했으면 삭제
    }


    private int createCode() {
        return (int) (Math.random() * 900000) + 100000;
    }

    private MimeMessage createMail(String recipientEmail, int number) {
        MimeMessage message = mailSender.createMimeMessage();

        try {
            message.setFrom(sender);
            message.setRecipients(MimeMessage.RecipientType.TO, recipientEmail);
            message.setSubject("[Ollana] 이메일 인증번호입니다.");

            String body = "<div style='font-family: Arial; padding: 20px;'>"
                    + "<h2 style='color:#4CAF50;'>[Ollana] 이메일 인증번호</h2>"
                    + "<div style='font-size: 28px; font-weight: bold; color: black; margin: 20px 0;'>"
                    + number + "</div>"
                    + "<p style='font-size: 12px; color: gray;'>인증번호는 5분간 유효합니다.</p>"
                    + "</div>";

            message.setText(body, "utf-8", "html");
        } catch (MessagingException e) {
            log.error("메일 전송 중 오류 발생", e);
            throw new MailSendException();
        }

        return message;
    }
}
