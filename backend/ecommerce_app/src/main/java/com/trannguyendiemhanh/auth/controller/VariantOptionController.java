package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.VariantOption;
import com.trannguyendiemhanh.auth.service.VariantOptionService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/variant-options")
public class VariantOptionController extends CrudController<VariantOption, UUID> {
    public VariantOptionController(VariantOptionService service) {
        super(service);
    }
}
