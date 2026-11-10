package com.supermarket.service;

import com.supermarket.entity.Category;
import com.supermarket.entity.Product;

import java.util.List;
import java.util.Map;

/**
 * 商品浏览服务 — 门户热点路径（首页、分类、详情）。
 *
 */
public interface ProductViewService {

    List<Map<String, Object>> home();

    List<Category> categories();

    Map<String, Object> getByCategory(Integer categoryId, Integer current, Integer size);

    Product detail(Integer id);
}
