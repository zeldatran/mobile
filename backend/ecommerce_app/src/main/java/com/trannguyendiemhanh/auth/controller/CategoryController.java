package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Category;
import com.trannguyendiemhanh.auth.service.CategoryService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/categories")
public class CategoryController extends CrudController<Category, UUID> {
    public CategoryController(CategoryService service) {
        super(service);
    }
}
