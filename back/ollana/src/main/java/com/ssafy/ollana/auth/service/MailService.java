package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.request.EmailSendRequestDto;
import com.ssafy.ollana.auth.dto.request.EmailVerifyRequestDto;
import com.ssafy.ollana.auth.exception.EmailCodeExpiredException;
import com.ssafy.ollana.auth.exception.InvalidEmailCodeException;
import com.ssafy.ollana.auth.exception.MailSendException;
import com.ssafy.ollana.user.exception.DuplicateEmailException;
import com.ssafy.ollana.user.repository.UserRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class MailService {

    @Value("${spring.mail.username}")
    private String sender;

    private final JavaMailSender mailSender;
    private final RedisTemplate<String, String> redisTemplate;
    private final UserRepository userRepository;

    // 이메일 인증 코드 메일 전송
    public void sendMail(EmailSendRequestDto request) {
        String recipientEmail = request.getEmail();

        // 이미 가입된 이메일인지 확인
        if (userRepository.existsByEmail(recipientEmail)) {
            throw new DuplicateEmailException();
        }

        int code = createCode();
        MimeMessage message = createMail(recipientEmail, code);

        try {
            mailSender.send(message);
        } catch (MailSendException e) {
            log.error("메일 전송 중 오류 발생", e);
            throw new MailSendException();
        }

        // redis에 인증 코드 저장
        redisTemplate.opsForValue().set(
                "emailCode:" + recipientEmail,
                String.valueOf(code),
                Duration.ofMinutes(5)
        );
    }

    // 이메일 인증 코드 검증
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

    // 비밀번호 재설정 메일 전송
    public void sendPasswordResetMail(String recipientEmail, String passwordResetToken) {
        MimeMessage message = createPasswordResetMail(recipientEmail, passwordResetToken);

        try {
            mailSender.send(message);
        } catch (MailSendException e) {
            log.error("비밀번호 재설정 이메일 전송 중 오류 발생", e);
            throw new MailSendException();
        }
    }


    // 이메일 인증 코드 생성
    private int createCode() {
        SecureRandom secureRandom = new SecureRandom();
        return secureRandom.nextInt(900000) + 100000;
    }

    // 이메일 인증 코드 메일 생성
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

    // 비밀번호 재설정 메일 생성
    private MimeMessage createPasswordResetMail(String recipientEmail, String passwordResetToken) {
        MimeMessage message = mailSender.createMimeMessage();

        try {
            message.setFrom(sender);
            message.setRecipients(MimeMessage.RecipientType.TO, recipientEmail);
            message.setSubject("[Ollana] 비밀번호 재설정 요청");

            String resetLink = "https://k12c104.p.ssafy.io/back-api/auth/password/change?token=" + passwordResetToken;

            String body = "<div style='font-family: Arial; padding: 20px;'>"
                    + "<h2 style='color:#4CAF50;'>[Ollana] 비밀번호 재설정 요청</h2>"
                    + "<p style='font-size: 16px;'>아래 링크를 클릭하여 비밀번호를 재설정하십시오:</p>"
                    + "<div style='font-size: 18px; font-weight: bold; color: black; margin: 20px 0;'>"
                    + "<a href='" + resetLink + "'>" + resetLink + "</a>"
                    + "</div>"
                    + "<p style='font-size: 12px; color: gray;'>이 링크는 10분 동안 유효합니다.</p>"
                    + "<p style='font-size: 12px; color: gray;'>만약 본인이 요청하지 않은 경우, 이 메일을 무시하셔도 됩니다.</p>"
                    + "</div>";

            message.setText(body, "utf-8", "html");
        } catch (MessagingException e) {
            log.error("메일 전송 중 오류 발생", e);
            throw new MailSendException();
        }

        return message;
    }
}
