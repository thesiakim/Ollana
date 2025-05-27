package com.ssafy.ollana.common.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.amqp.core.Queue;

@Configuration
public class RabbitMQConfig {

    public static final String HIKING_RECORDS_QUEUE = "hiking-records-queue";
    public static final String HIKING_RECORDS_DLQ = "hiking-records-dlq";
    public static final String EXCHANGE = "hiking-records-exchange";
    public static final String ROUTING_KEY = "hiking-records";

    @Bean
    public Queue hikingRecordsQueue() {
        return QueueBuilder.durable(HIKING_RECORDS_QUEUE)
                .withArgument("x-dead-letter-exchange", EXCHANGE)
                .withArgument("x-dead-letter-routing-key", ROUTING_KEY + ".dlq")
                .build();
    }

    @Bean
    public Queue hikingRecordsDlq() {
        return new Queue(HIKING_RECORDS_DLQ, true);
    }

    @Bean
    public DirectExchange hikingRecordsExchange() {
        return new DirectExchange(EXCHANGE);
    }

    @Bean
    public Binding binding() {
        return BindingBuilder.bind(hikingRecordsQueue())
                .to(hikingRecordsExchange())
                .with(ROUTING_KEY);
    }

    @Bean
    public Binding dlqBinding() {
        return BindingBuilder.bind(hikingRecordsDlq())
                .to(hikingRecordsExchange())
                .with(ROUTING_KEY + ".dlq");
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        return template;
    }
}