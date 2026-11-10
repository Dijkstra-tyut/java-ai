package com.supermarket.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.supermarket.entity.Category;
import org.apache.ibatis.annotations.Param;
import java.util.List;
public interface CategoryMapper extends BaseMapper<Category> {
    List<Category> selectAll();
    List<Category> selectByParentId(@Param("parentId") Integer parentId);
}
