package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductCategory;
import com.trannguyendiemhanh.auth.service.ProductCategoryService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-categories")
public class ProductCategoryController extends CrudController<ProductCategory, UUID> {
    public ProductCategoryController(ProductCategoryService service) {
        super(service);
    }
}
