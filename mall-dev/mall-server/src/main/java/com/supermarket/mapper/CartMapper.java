package com.supermarket.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.supermarket.entity.Cart;
import org.apache.ibatis.annotations.Param;
import java.util.List;
public interface CartMapper extends BaseMapper<Cart> {
    List<Cart> selectByUserId(@Param("userId") Integer userId);
    Cart selectByUserIdAndProductId(@Param("userId") Integer userId, @Param("productId") Integer productId);
}
