package com.supermarket.job;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.supermarket.entity.Order;
import com.supermarket.mapper.OrderMapper;
import com.supermarket.service.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/** Local fallback for unpaid orders when the RabbitMQ listener is disabled. */
@Component
@ConditionalOnProperty(name = "mall.rabbitmq.listeners-enabled", havingValue = "false")
public class LocalOrderTimeoutJob {
    private static final Logger log = LoggerFactory.getLogger(LocalOrderTimeoutJob.class);
    private final OrderMapper orderMapper;
    private final OrderService orderService;

    public LocalOrderTimeoutJob(OrderMapper orderMapper, OrderService orderService) {
        this.orderMapper = orderMapper;
        this.orderService = orderService;
    }

    @Scheduled(fixedDelay = 60_000)
    public void cancelExpired() {
        var expired = orderMapper.selectList(new QueryWrapper<Order>()
                .eq("status", 0)
                .eq("is_deleted", 0)
                .lt("create_time", LocalDateTime.now().minusMinutes(10)));
        for (Order order : expired) {
            try {
                orderService.cancel(order.getId());
            } catch (Exception exception) {
                log.warn("Could not cancel expired order {}: {}", order.getId(), exception.getMessage());
            }
        }
    }
}
