package com.supermarket.exception;

import com.supermarket.enums.BaseEnum;
import lombok.Getter;
import org.apache.poi.ss.formula.functions.T;

/**
 * 自定义异常
 */
@Getter
public class ServiceException extends RuntimeException {
    private final int code;

    public ServiceException(int code,String message){
        super(message);
        this.code = code;
    }

    public ServiceException(BaseEnum<T> e){
        super(e.getMessage());
        this.code = e.getCode();
    }


}
