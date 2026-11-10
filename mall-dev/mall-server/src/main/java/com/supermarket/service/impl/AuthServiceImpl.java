package com.supermarket.service.impl;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.supermarket.entity.User;
import com.supermarket.entity.ValidateCode;
import com.supermarket.enums.BusinessStatusEnum;
import com.supermarket.enums.UserStatusEnum;
import com.supermarket.exception.ServiceException;
import com.supermarket.mapper.UserMapper;
import com.supermarket.service.AuthService;
import com.supermarket.util.DeviceUtils;
import com.supermarket.util.RedisUtil;
import com.supermarket.util.ValidateCodeUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class AuthServiceImpl extends ServiceImpl<UserMapper, User> implements AuthService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final RedisUtil redisUtil;

    public AuthServiceImpl(UserMapper userMapper, PasswordEncoder passwordEncoder, RedisUtil redisUtil) {
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
        this.redisUtil = redisUtil;
    }

    @Override
    public void register(String code, String password, String phone, String verificationCode, String uuid) {
        if (code == null || code.isBlank() || password == null || password.isBlank()) {
            throw new ServiceException(BusinessStatusEnum.AUTH_EMPTY_CREDENTIALS);
        }
        if (uuid == null || uuid.isBlank()) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_NOT_EXIST);
        }
        String codeInRedis = (String) redisUtil.get("validate:code:" + uuid);
        if (codeInRedis == null) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_NOT_EXIST);
        }
        if (!codeInRedis.equals(verificationCode)) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_ERROR);
        }
        redisUtil.del("validate:code:" + uuid);

        User exist = userMapper.selectOne(new QueryWrapper<User>().eq("code", code));
        if (exist != null) {
            throw new ServiceException(BusinessStatusEnum.USERNAME_EXISTS);
        }
        User user = new User();
        user.setCode(code);
        user.setName(code);
        user.setPassword(passwordEncoder.encode(password));
        user.setPhone(phone);
        user.setStatus(UserStatusEnum.ENABLED);
        userMapper.insert(user);
    }

    @Override
    public Map<String, Object> login(String code, String password, String verificationCode, String uuid, String pathPrefix, HttpServletRequest request) {
        if (uuid == null || uuid.isBlank()) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_NOT_EXIST);
        }
        String codeInRedis = (String) redisUtil.get("validate:code:" + uuid);
        if (codeInRedis == null) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_NOT_EXIST);
        }
        if (!codeInRedis.equals(verificationCode)) {
            throw new ServiceException(BusinessStatusEnum.CAPTCHA_ERROR);
        }
        redisUtil.del("validate:code:" + uuid);

        User existUser = userMapper.selectOne(new QueryWrapper<User>().eq("code", code));
        if (existUser == null) {
            throw new ServiceException(BusinessStatusEnum.USER_NOT_EXIST);
        }
        if (existUser.getStatus() == UserStatusEnum.DISABLED) {
            throw new ServiceException(BusinessStatusEnum.ACCOUNT_DISABLED);
        }
        if (!passwordEncoder.matches(password, existUser.getPassword())) {
            throw new ServiceException(BusinessStatusEnum.PASSWORD_ERROR);
        }

        String role = pathPrefix.startsWith("/admin") ? "admin" : "portal";
        String device = DeviceUtils.getRequestDevice(request);
        StpUtil.login(existUser.getId(), role + ":" + device);
        StpUtil.getSession().set("device", device);
        StpUtil.getSession().set("user", existUser);

        return Map.of("user", existUser, "token", StpUtil.getTokenValue());
    }

    @Override
    public Map<String, Object> getVerificationCode() {
        ValidateCode validateCode = ValidateCodeUtil.generateValidateCode();
        String uuid = java.util.UUID.randomUUID().toString().replace("-", "");
        redisUtil.set("validate:code:" + uuid, validateCode.getCode(), 60);
        return Map.of("uuid", uuid, "image", validateCode.getImage());
    }

    @Override
    public void logout(String token, String requestUri) {
        StpUtil.logout();
    }
}
