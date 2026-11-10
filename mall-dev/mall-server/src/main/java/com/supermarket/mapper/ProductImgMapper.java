package com.supermarket.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.supermarket.entity.ProductImg;
import org.apache.ibatis.annotations.Param;
import java.util.List;
public interface ProductImgMapper extends BaseMapper<ProductImg> {
    List<ProductImg> selectByProductId(@Param("productId") Integer productId);
    List<ProductImg> selectByProductIds(@Param("productIds") List<Integer> productIds);
    ProductImg selectFirstByProductId(@Param("productId") Integer productId);
    int insertBatch(@Param("imgs") List<ProductImg> imgs);
}
