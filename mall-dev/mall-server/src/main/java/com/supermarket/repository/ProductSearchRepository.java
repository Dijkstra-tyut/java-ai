package com.supermarket.repository;

import com.supermarket.document.ProductDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

/**
 * 商品 ES 搜索仓库
 *
 */
public interface ProductSearchRepository extends ElasticsearchRepository<ProductDocument, Integer> {
}
