package com.supermarket.service;

import com.supermarket.entity.Category;

import java.util.List;

public interface CategoryService {

    List<Category> tree();

    List<Category> all();

    void add(Category category);

    void edit(Category category);

    void delete(Integer id);
}
