package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Category;
import com.trannguyendiemhanh.auth.repository.CategoryRepository;
import com.trannguyendiemhanh.auth.service.CategoryService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CategoryServiceImpl extends JpaCrudServiceImpl<Category, UUID> implements CategoryService {
    public CategoryServiceImpl(CategoryRepository repository) {
        super(repository);
    }
}
