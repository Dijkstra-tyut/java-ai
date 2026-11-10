package com.supermarket.service;

import com.supermarket.vo.CategorySalesVO;

import java.util.List;
import java.util.Map;

public interface HomeService {

    Map<String, Object> getCount();

    List<Map<String, Object>> getTrend(Integer days);

    List<CategorySalesVO> getCategorySales();
}
