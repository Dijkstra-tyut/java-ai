package com.supermarket.dto;

import com.supermarket.enums.BaseEnum;
import com.supermarket.enums.BusinessStatusEnum;

/**
 * 响应工厂类
 */
public class Response {

    public static <T> ResponseDTO<T> success() {
        return ResponseDTO.success();
    }

    public static <T> ResponseDTO<T> success(T data) {
        return ResponseDTO.success(data);
    }

    public static <T> ResponseDTO<T> success(String message, T data) {
        return new ResponseDTO<>(200, message, data);
    }

    public static ResponseDTO<Void> ok(String message) {
        return new ResponseDTO<>(200, message, null);
    }

    public static <T> ResponseDTO<T> error() {
        return ResponseDTO.error("失败");
    }

    public static <T> ResponseDTO<T> error(String message) {
        return ResponseDTO.error(message);
    }

    public static <T> ResponseDTO<T> error(Integer code, String message) {
        return ResponseDTO.error(code, message);
    }

    public static <T> ResponseDTO<T> error(BaseEnum<?> e) {
        return new ResponseDTO<>(e.getCode(), e.getMessage(), null);
    }
}
