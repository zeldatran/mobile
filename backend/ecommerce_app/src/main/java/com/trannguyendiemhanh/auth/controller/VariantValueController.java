package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.VariantValue;
import com.trannguyendiemhanh.auth.service.VariantValueService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/variant-values")
public class VariantValueController extends CrudController<VariantValue, UUID> {
    public VariantValueController(VariantValueService service) {
        super(service);
    }
}
