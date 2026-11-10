package com.supermarket.mq;

import lombok.Data;
import java.io.Serializable;

/**
 * 订单超时取消延时消息体
 *
 */
@Data
public class OrderTimeoutMessage implements Serializable {

    private static final long serialVersionUID = 1L;
    private Integer orderId;
}
