package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductCategory;
import com.trannguyendiemhanh.auth.repository.ProductCategoryRepository;
import com.trannguyendiemhanh.auth.service.ProductCategoryService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductCategoryServiceImpl extends JpaCrudServiceImpl<ProductCategory, UUID> implements ProductCategoryService {
    public ProductCategoryServiceImpl(ProductCategoryRepository repository) {
        super(repository);
    }
}
